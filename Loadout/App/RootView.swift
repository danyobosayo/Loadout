import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable, Identifiable {
    case build, recipes, history, settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .build: "Build"
        case .recipes: "Recipes"
        case .history: "History"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .build: "fork.knife"
        case .recipes: "bookmark.fill"
        case .history: "clock.arrow.circlepath"
        case .settings: "gearshape.fill"
        }
    }
}

struct RootView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var tab: AppTab = .build

    var body: some View {
        // All four tabs stay mounted (opacity-switched) so scroll
        // positions and in-progress meals survive tab hops.
        ZStack {
            RestaurantsView()
                .opacity(tab == .build ? 1 : 0)
                .allowsHitTesting(tab == .build)
            RecipesView()
                .opacity(tab == .recipes ? 1 : 0)
                .allowsHitTesting(tab == .recipes)
            HistoryView()
                .opacity(tab == .history ? 1 : 0)
                .allowsHitTesting(tab == .history)
            SettingsView()
                .opacity(tab == .settings ? 1 : 0)
                .allowsHitTesting(tab == .settings)
        }
        .overlay(alignment: .bottom) {
            FloatingTabBar(selection: $tab)
        }
        .preferredColorScheme(.dark)
        .tint(.volt)
        .fullScreenCover(isPresented: Binding(
            get: { !settings.hasCompletedOnboarding },
            set: { isPresented in
                if !isPresented {
                    settings.hasCompletedOnboarding = true
                }
            }
        )) {
            OnboardingView()
        }
    }
}

/// Floating glass tab bar — STYLE_GUIDE.md §7. Volt pill slides
/// between tabs with matched geometry; selected icon sits on volt in
/// void ink, with the label revealed beside it.
private struct FloatingTabBar: View {
    @Binding var selection: AppTab
    @Namespace private var pill

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(6)
        .background {
            Capsule()
                .fill(Color.surfaceElevated)
                .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xs)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selection == tab
        return Button {
            guard selection != tab else { return }
            Haptics.tap()
            withAnimation(Motion.snap) { selection = tab }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .symbolEffect(.bounce, value: isSelected)
                if isSelected {
                    Text(tab.label)
                        .font(.appCaption.weight(.semibold))
                        .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
                }
            }
            .foregroundStyle(isSelected ? Color.void : .textSecondary)
            .padding(.horizontal, isSelected ? 14 : 12)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.volt)
                        .matchedGeometryEffect(id: "tab-pill", in: pill)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    RootView()
        .environment(SettingsStore())
        .modelContainer(for: [FavoriteMeal.self, LoggedMeal.self], inMemory: true)
}
