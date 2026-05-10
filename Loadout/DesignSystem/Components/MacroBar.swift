import SwiftUI

struct MacroBar: View {
    let macros: Macros
    var style: MacroDisplay.Style = .hero

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.lg) {
            MacroDisplay(kind: .calories, value: macros.calories, style: style)
            MacroDisplay(kind: .protein, value: macros.proteinGrams, style: style)
            MacroDisplay(kind: .carbs, value: macros.carbGrams, style: style)
            MacroDisplay(kind: .fat, value: macros.fatGrams, style: style)
        }
    }
}
