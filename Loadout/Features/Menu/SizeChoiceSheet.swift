import SwiftUI

/// Which size of a dish is being chosen, and where it goes.
struct SizeChoice: Identifiable {
    let group: SizeGroup
    let categoryId: String
    var id: String { group.id }
}

/// Pick a size.
///
/// A sheet rather than a control in the row, for a reason worth recording: both
/// station-row shapes wrap their content in a Button, so any interactive
/// element placed inside a row — chips, a Menu — never receives its own taps.
/// Giving the row a second shape to make room for one changed the layout and
/// accessibility tree of the entire station list badly enough that unrelated UI
/// queries went from 29 seconds to timing out at 190. The row is untouched;
/// this opens on top of it.
struct SizeChoiceSheet: View {
    let group: SizeGroup
    let accent: Color
    let quantityFor: (MenuItem) -> Double
    let onPick: (MenuItem) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.sm) {
                    ForEach(group.members) { member in
                        row(member)
                    }
                }
                .padding(Spacing.md)
            }
            .background(Backdrop())
            .navigationTitle(group.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func row(_ member: MenuItem) -> some View {
        let inTray = quantityFor(member) > 0
        return Button {
            Haptics.tap()
            onPick(member)
            dismiss()
        } label: {
            Card(padding: Spacing.sm + Spacing.xs, highlight: inTray ? accent : nil) {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                            Text(member.sizeLabel ?? member.name)
                                .font(.appHeadline)
                                .foregroundStyle(.textPrimary)
                            Spacer(minLength: 0)
                            Text(member.servingDescription)
                                .font(.appCaption)
                                .foregroundStyle(.textTertiary)
                                .lineLimit(1)
                        }
                        MacroStrip(macros: member.macros)
                    }
                    if inTray {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(accent)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .buttonStyle(.pressable)
        .accessibilityIdentifier("size.\(member.id)")
        .accessibilityLabel(
            "\(member.sizeLabel ?? member.name), \(member.servingDescription), "
            + "\(Int(member.macros.calories.rounded())) calories"
        )
        .accessibilityAddTraits(inTray ? [.isSelected] : [])
    }
}
