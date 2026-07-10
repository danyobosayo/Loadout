import SwiftUI
import UIKit

// OBSIDIAN motion system — STYLE_GUIDE.md §4.
// Four named springs. Feature code never writes a raw animation.
nonisolated enum Motion {
    /// Press compress/release on every tappable surface.
    static let tap = Animation.spring(response: 0.22, dampingFraction: 0.7)
    /// Selection, quantity ticks, chips, rail pill.
    static let snap = Animation.spring(response: 0.35, dampingFraction: 0.75)
    /// Layout shifts, tray expansion, ring sweeps.
    static let glide = Animation.spring(response: 0.5, dampingFraction: 0.85)
    /// Entrance cascade delay for element `index` (capped per §4).
    static func entranceDelay(_ index: Int) -> Double {
        min(Double(index) * 0.04, 0.4)
    }
}

// MARK: - Entrance choreography

/// Cascading list entrance: opacity 0 → 1, y +14 → 0, staggered
/// 40 ms per index. Runs once on appear; disabled entirely
/// under Reduce Motion (elements simply appear).
private struct EntranceModifier: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                guard !shown else { return }
                if reduceMotion {
                    shown = true
                } else {
                    withAnimation(Motion.snap.delay(Motion.entranceDelay(index))) {
                        shown = true
                    }
                }
            }
    }
}

// MARK: - Press state

/// The universal press state: scale 0.96 on `Motion.tap`.
/// Applied via `.buttonStyle(.pressable)` on every card and row.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(Motion.tap, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}

extension View {
    /// Cascading entrance for the `index`-th element of a list.
    func entrance(_ index: Int) -> some View {
        modifier(EntranceModifier(index: index))
    }
}

// MARK: - Haptics

/// Fired at store/action boundaries (add, save, limit), not sprinkled
/// through view bodies — STYLE_GUIDE.md §4. Generators are kept alive and
/// re-prepared after each fire so the first tap after idle isn't dropped.
@MainActor
enum Haptics {
    private static let impact = UIImpactFeedbackGenerator(style: .light)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notification = UINotificationFeedbackGenerator()

    /// Warm the engine where tapping is imminent (call on screen appear).
    static func prepare() {
        impact.prepare()
        selectionGenerator.prepare()
    }

    /// A light impact — something landed (added a portion, opened a sheet).
    static func tap() {
        impact.impactOccurred()
        impact.prepare()
    }

    /// Discrete selection — moving between tabs, rail chapters, chips.
    static func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    static func success() {
        notification.notificationOccurred(.success)
    }

    static func warning() {
        notification.notificationOccurred(.warning)
    }
}
