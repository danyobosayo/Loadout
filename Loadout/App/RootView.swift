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
    @Environment(MacroFactorExport.self) private var macroFactorExport
    @Environment(\.modelContext) private var modelContext
    @State private var tab: AppTab = .build
    @State private var bannerDismiss: Task<Void, Never>?

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
        // A quick crossfade for the content — the springy Motion.snap that
        // slides the pill would ghost a full-screen opacity switch for ~0.5s.
        .animation(.easeInOut(duration: 0.18), value: tab)
        .onAppear { Haptics.prepare() }
        .overlay(alignment: .bottom) {
            FloatingTabBar(selection: $tab)
        }
        .overlay(alignment: .top) {
            if let outcome = macroFactorExport.lastOutcome {
                resultBanner(outcome)
            }
        }
        .preferredColorScheme(.dark)
        .tint(.volt)
        // The MacroFactor Shortcut returns here via loadout:// when it
        // finishes — so we log to history + confirm only on a real success.
        .onOpenURL { url in handleCallback(url) }
        .onChange(of: macroFactorExport.lastOutcome) { _, outcome in
            bannerDismiss?.cancel()
            guard let outcome else { return }
            // The banner is the key confirmation — speak it, since VoiceOver
            // users can't see the top overlay flash by.
            AccessibilityNotification.Announcement(
                outcome == .logged
                    ? "Logged to MacroFactor"
                    : "Couldn't log. Tap the banner to check your shortcut in Settings."
            ).post()
            // Success flashes and fades; a failure sticks until tapped so the
            // user can actually act on it (it deep-links to Settings).
            guard outcome == .logged else { return }
            bannerDismiss = Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.6))
                guard !Task.isCancelled else { return }
                withAnimation(Motion.snap) { macroFactorExport.lastOutcome = nil }
            }
        }
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

    private func handleCallback(_ url: URL) {
        withAnimation(Motion.snap) {
            if let meal = macroFactorExport.resolve(url) {
                recordHistory(meal: meal)
                Haptics.success()
            } else if macroFactorExport.lastOutcome == .failed {
                Haptics.warning()
            }
        }
    }

    private func recordHistory(meal: BuiltMeal) {
        let logged = LoggedMeal(
            restaurantId: meal.restaurantId,
            loggedAt: meal.createdAt,
            lineItems: meal.lineItems
        )
        modelContext.insert(logged)
        do {
            try LoggedMealRetention.enforceLimit(in: modelContext)
            try modelContext.save()
        } catch {
            // The MacroFactor log already happened. A local persistence
            // failure is recoverable next log — don't surface it.
        }
    }

    @ViewBuilder
    private func resultBanner(_ outcome: MacroFactorExport.Outcome) -> some View {
        if outcome == .logged {
            bannerChrome(logged: true)
                .accessibilityAddTraits(.isStaticText)
        } else {
            // A failure is tappable and persistent — it takes you to Settings
            // to fix the shortcut instead of vanishing in 2.6s.
            Button {
                Haptics.tap()
                withAnimation(Motion.snap) {
                    macroFactorExport.lastOutcome = nil
                    tab = .settings
                }
            } label: {
                bannerChrome(logged: false)
            }
            .buttonStyle(.pressable)
            .accessibilityHint("Opens Settings to check your shortcut")
        }
    }

    private func bannerChrome(logged: Bool) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: logged ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(logged ? Color.volt : Color.fat)
            Text(logged ? "Logged to MacroFactor" : "Couldn't log — tap to check Settings")
            if !logged {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.textTertiary)
            }
        }
        .font(.appCaption.weight(.semibold))
        .foregroundStyle(.textPrimary)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background {
            Capsule()
                .fill(Color.surfaceElevated)
                .overlay(Capsule().strokeBorder((logged ? Color.volt : Color.fat).opacity(0.4), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
        }
        .padding(.top, Spacing.sm)
        .transition(.move(edge: .top).combined(with: .opacity))
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
            Haptics.selection()
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
