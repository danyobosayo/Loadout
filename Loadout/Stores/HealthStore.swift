import Foundation
@preconcurrency import HealthKit
import Observation

/// Reads today's consumed nutrition from Apple Health so the targeting layer
/// can show what's left: `remaining = target − consumed`. **Read-only** — the
/// app never writes to Health. Phase 2 of the premium plan; Budget Mode and the
/// solver (Phase 3+) read `remaining(against:)`.
///
/// Note: HealthKit deliberately hides whether *read* access was granted (for
/// privacy), so "connected" only means we asked — an empty read is
/// indistinguishable from "no permission." The UI reflects that honestly.
@MainActor
@Observable
final class HealthStore {
    enum Status: Equatable {
        case unavailable    // no HealthKit on this device
        case notConnected   // available, not yet asked
        case connected      // we've requested authorization
    }

    private(set) var status: Status
    /// Today's consumed macros, or nil until a successful read.
    private(set) var consumedToday: Macros?

    private let store: HKHealthStore?
    private let defaults: UserDefaults

    private static let readTypes: Set<HKObjectType> = [
        HKQuantityType(.dietaryEnergyConsumed),
        HKQuantityType(.dietaryProtein),
        HKQuantityType(.dietaryCarbohydrates),
        HKQuantityType(.dietaryFatTotal),
    ]

    private static let writeTypes: Set<HKSampleType> = [
        HKQuantityType(.dietaryEnergyConsumed),
        HKQuantityType(.dietaryProtein),
        HKQuantityType(.dietaryCarbohydrates),
        HKQuantityType(.dietaryFatTotal),
    ]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if HKHealthStore.isHealthDataAvailable() {
            store = HKHealthStore()
            // HealthKit hides read-grant status, so we persist that we asked —
            // otherwise returning users see the Connect CTA (and no readout)
            // on every cold launch. refreshToday() runs at app launch/foreground.
            status = defaults.bool(forKey: Keys.connectRequested) ? .connected : .notConnected
        } else {
            store = nil
            status = .unavailable
        }
    }

    /// What remains of `target` after today's consumption. **Signed** — negative
    /// means over budget. Nil until Health has been read.
    func remaining(against target: Macros) -> Macros? {
        guard let consumedToday else { return nil }
        return target - consumedToday
    }

    /// Request read access, then load today. Safe to call repeatedly.
    func connect() async {
        guard let store else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: Self.readTypes)
            defaults.set(true, forKey: Keys.connectRequested)
            status = .connected
            await refreshToday()
        } catch {
            // Authorization can throw (user dismissed, missing entitlement) —
            // stay notConnected so the UI can offer to retry.
        }
    }

    /// Write a meal's macros to Apple Health as one food entry (energy + P/C/F),
    /// requesting write access on first use. Returns false if unavailable or the
    /// save failed. A native alternative to the MacroFactor Shortcut hand-off.
    func logMeal(named name: String, macros: Macros, at date: Date = Date()) async -> Bool {
        guard let store else { return false }
        do {
            try await store.requestAuthorization(toShare: Self.writeTypes, read: Self.readTypes)
        } catch {
            return false
        }
        let samples: [HKSample] = [
            sample(.dietaryEnergyConsumed, unit: .kilocalorie(), value: macros.calories, at: date),
            sample(.dietaryProtein, unit: .gram(), value: macros.proteinGrams, at: date),
            sample(.dietaryCarbohydrates, unit: .gram(), value: macros.carbGrams, at: date),
            sample(.dietaryFatTotal, unit: .gram(), value: macros.fatGrams, at: date),
        ]
        let food = HKCorrelation(
            type: HKCorrelationType(.food),
            start: date, end: date,
            objects: Set(samples),
            metadata: [HKMetadataKeyFoodType: name]
        )
        do {
            try await store.save(food)
            if status == .connected { await refreshToday() }   // reflect it in "eaten today"
            return true
        } catch {
            return false
        }
    }

    private func sample(_ id: HKQuantityTypeIdentifier, unit: HKUnit, value: Double, at date: Date) -> HKQuantitySample {
        HKQuantitySample(
            type: HKQuantityType(id),
            quantity: HKQuantity(unit: unit, doubleValue: max(0, value)),
            start: date, end: date
        )
    }

    /// Re-read today's totals. Call on connect and when the app foregrounds.
    func refreshToday() async {
        guard let store, status == .connected else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())

        // Sequential (not `async let`): the queries are fast, and NSPredicate
        // isn't Sendable, so keeping them on this actor avoids a data race.
        let energy = await Self.sum(.dietaryEnergyConsumed, unit: .kilocalorie(), predicate: predicate, store: store)
        let protein = await Self.sum(.dietaryProtein, unit: .gram(), predicate: predicate, store: store)
        let carbs = await Self.sum(.dietaryCarbohydrates, unit: .gram(), predicate: predicate, store: store)
        let fat = await Self.sum(.dietaryFatTotal, unit: .gram(), predicate: predicate, store: store)

        consumedToday = Macros(calories: energy, proteinGrams: protein, carbGrams: carbs, fatGrams: fat)
    }

    /// Cumulative sum of one quantity type for the predicate window. Runs the
    /// query off the main actor; returns 0 for no samples / no access.
    private static func sum(
        _ id: HKQuantityTypeIdentifier,
        unit: HKUnit,
        predicate: NSPredicate,
        store: HKHealthStore
    ) async -> Double {
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: HKQuantityType(id),
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }

    private enum Keys {
        static let connectRequested = "loadout.health.connectRequested"
    }
}
