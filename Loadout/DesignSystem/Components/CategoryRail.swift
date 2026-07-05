import SwiftUI

/// The "chapters" bar — station pills pinned under the nav inside a
/// menu. Read-only with respect to selection: the pill highlights
/// whatever the owner says (scroll position or an in-flight tap
/// target) and reports taps up via `onTap`. Owning the state in one
/// place is what makes tap-during-deceleration deterministic.
struct CategoryRail: View {
    let categories: [MenuCategory]
    let selection: String?
    var hue: Color = .volt
    var onTap: (String) -> Void = { _ in }

    @Namespace private var pill

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(categories) { category in
                        railPill(category)
                            .id("rail-\(category.id)")
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .onChange(of: selection) { _, newValue in
                guard let newValue else { return }
                withAnimation(Motion.snap) {
                    proxy.scrollTo("rail-\(newValue)", anchor: .center)
                }
            }
        }
        .background(Color.void)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.hairline).frame(height: 1)
        }
    }

    private func railPill(_ category: MenuCategory) -> some View {
        let isSelected = selection == category.id
        return Button {
            Haptics.tap()
            onTap(category.id)
        } label: {
            HStack(spacing: 5) {
                Image(category.style.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                Text(category.name)
                    .font(.appCaption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? Color.void : .textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background {
                if isSelected {
                    Capsule()
                        .fill(hue)
                        .matchedGeometryEffect(id: "selection", in: pill)
                } else {
                    Capsule()
                        .fill(Color.white.opacity(0.04))
                        .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 1))
                }
            }
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("\(category.name) station")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
