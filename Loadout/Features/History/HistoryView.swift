import SwiftUI
import SwiftData

/// Auto-kept log of everything sent to MacroFactor (last 50, FIFO).
/// Tap any entry to rebuild it in the tray.
struct HistoryView: View {
    @Query(sort: [SortDescriptor(\LoggedMeal.loggedAt, order: .reverse)])
    private var logs: [LoggedMeal]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                Backdrop(tint: .volt)

                if logs.isEmpty {
                    EmptyStateView(
                        systemImage: "clock.arrow.circlepath",
                        title: "Nothing logged yet",
                        message: "Meals you log to MacroFactor appear here automatically."
                    )
                } else {
                    list
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: LoggedMeal.self) { logged in
                ReopenLoggedMealView(logged: logged)
            }
        }
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xs) {
                masthead
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.sm)

                ForEach(Array(logs.enumerated()), id: \.element.id) { index, logged in
                    NavigationLink(value: logged) {
                        LoggedMealCard(logged: logged) {
                            Haptics.warning()
                            withAnimation(Motion.glide) {
                                modelContext.delete(logged)
                                try? modelContext.save()
                            }
                        }
                    }
                    .buttonStyle(.pressable)
                    .entrance(index + 1)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .contentMargins(.bottom, Metrics.tabBarClearance, for: .scrollContent)
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Logged meals")
                .microLabelStyle(.volt)
            Text("History")
                .displayXLStyle()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct LoggedMealCard: View {
    let logged: LoggedMeal
    let onDelete: () -> Void

    var body: some View {
        Card {
            HStack(spacing: Spacing.md) {
                identityTile

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(ExportService.displayName(forRestaurantId: logged.restaurantId))
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                        Spacer(minLength: Spacing.xs)
                        Text(logged.loggedAt, format: .relative(presentation: .named))
                            .font(.appCaption)
                            .foregroundStyle(.textTertiary)
                    }
                    Text("^[\(logged.lineItems.count) item](inflect: true)")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    MacroBar(macros: logged.totalMacros, style: .inline)
                }
            }
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete from history", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(ExportService.displayName(forRestaurantId: logged.restaurantId)), \(ExportService.summaryLine(logged.totalMacros))"
        )
    }

    private var identityTile: some View {
        let style = Restaurant.style(forId: logged.restaurantId)
        return Image(style.icon)
            .resizable()
            .scaledToFit()
            .frame(width: 21, height: 21)
            .foregroundStyle(Color.void)
            .frame(width: 40, height: 40)
            .background {
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .fill(style.hue)
            }
            .accessibilityHidden(true)
    }
}

private struct ReopenLoggedMealView: View {
    let logged: LoggedMeal
    @Environment(\.menuRepository) private var menuRepository
    @State private var restaurant: Restaurant?
    @State private var loadError: String?

    var body: some View {
        ZStack {
            Backdrop(tint: Restaurant.style(forId: logged.restaurantId).hue)
            if let restaurant {
                MenuView(restaurant: restaurant, seed: logged.lineItems)
            } else if let loadError {
                EmptyStateView(
                    systemImage: "exclamationmark.triangle",
                    title: "Couldn't reopen",
                    message: loadError,
                    tint: .destructiveRed
                )
            } else {
                ProgressView().tint(.volt).task(id: logged.id) {
                    do {
                        restaurant = try await menuRepository.loadRestaurant(id: logged.restaurantId)
                    } catch {
                        loadError = error.localizedDescription
                    }
                }
            }
        }
    }
}
