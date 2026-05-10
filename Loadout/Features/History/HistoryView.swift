import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: [SortDescriptor(\LoggedMeal.loggedAt, order: .reverse)])
    private var logs: [LoggedMeal]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if logs.isEmpty {
                    ContentUnavailableView(
                        "No history yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Meals you log to MacroFactor will show up here automatically.")
                    )
                } else {
                    list
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: LoggedMeal.self) { logged in
                ReopenLoggedMealView(logged: logged)
            }
        }
    }

    private var list: some View {
        List {
            ForEach(logs) { logged in
                NavigationLink(value: logged) {
                    LoggedMealRow(logged: logged)
                }
            }
            .onDelete(perform: delete)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(logs[index])
        }
        try? modelContext.save()
    }
}

private struct LoggedMealRow: View {
    let logged: LoggedMeal

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(logged.restaurantId.capitalized)
                    .font(.appBody)
                Spacer()
                Text(logged.loggedAt, format: .relative(presentation: .named))
                    .font(.appCaption)
                    .foregroundStyle(.appSecondaryText)
            }
            MacroBar(macros: logged.totalMacros, style: .inline)
            Text("^[\(logged.lineItems.count) item](inflect: true)")
                .font(.appCaption)
                .foregroundStyle(.appSecondaryText)
        }
        .padding(.vertical, 4)
    }
}

private struct ReopenLoggedMealView: View {
    let logged: LoggedMeal
    @Environment(\.menuRepository) private var menuRepository
    @State private var restaurant: Restaurant?
    @State private var loadError: String?

    var body: some View {
        Group {
            if let restaurant {
                MenuView(restaurant: restaurant, seed: logged.lineItems)
            } else if let loadError {
                ContentUnavailableView(
                    "Couldn't reopen this meal",
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else {
                ProgressView().task(id: logged.id) {
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
