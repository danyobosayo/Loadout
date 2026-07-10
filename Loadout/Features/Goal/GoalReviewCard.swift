import SwiftUI

/// Read-only preview of a daily target — the calorie ring + P/C/F trio, plus
/// the maintenance line and safety notes when the target was generated.
/// Shared by both setup modes (manual shows a live preview with no notes).
struct GoalReviewCard: View {
    let target: Macros
    var maintenance: Double? = nil
    var floorApplied: Bool = false
    var rateClamped: Bool = false
    var achievableWeeks: Int? = nil

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.lg) {
                    MacroRing(calories: target.calories, size: 104)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        MacroDisplay(kind: .protein, value: target.proteinGrams, style: .hero)
                        MacroDisplay(kind: .carbs, value: target.carbGrams, style: .hero)
                        MacroDisplay(kind: .fat, value: target.fatGrams, style: .hero)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let maintenance {
                    Text("Maintenance ≈ \(Int(maintenance.rounded())) kcal")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                if floorApplied {
                    note("We set a safe minimum — eating below this isn't recommended.")
                }
                if rateClamped {
                    if let achievableWeeks {
                        note("We slowed this to a safe pace — expect about \(achievableWeeks) weeks.")
                    } else {
                        note("We slowed this to a safe pace.")
                    }
                }
            }
        }
    }

    private func note(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs + 2) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.fat)
                .accessibilityHidden(true)
            Text(text)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
