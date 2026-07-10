import SwiftUI

/// Navigation value for entering the builder. A chosen `format` drives
/// guided entry; `nil` is the build-your-own path (today's behavior).
nonisolated struct MenuRoute: Hashable {
    let restaurant: Restaurant
    let format: OrderFormat?
}

/// The counter moment — shown when a restaurant is tapped, before the
/// stations. Big format cards ("what are you ordering?") plus a
/// build-your-own escape hatch for power users. Formats load async; an
/// empty result just leaves build-your-own, so this never dead-ends.
struct FormatPickerView: View {
    let restaurant: Restaurant
    @Environment(\.menuRepository) private var menuRepository
    @State private var formats: [OrderFormat] = []

    var body: some View {
        ZStack {
            Backdrop(tint: restaurant.style.hue, intensity: 0.12)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xs) {
                    masthead
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, Spacing.sm)

                    ForEach(Array(formats.enumerated()), id: \.element.id) { index, format in
                        NavigationLink(value: MenuRoute(restaurant: restaurant, format: format)) {
                            FormatCard(format: format, hue: restaurant.style.hue)
                        }
                        .buttonStyle(.pressable)
                        .entrance(index + 1)
                    }

                    NavigationLink(value: MenuRoute(restaurant: restaurant, format: nil)) {
                        BuildYourOwnCard()
                    }
                    .buttonStyle(.pressable)
                    .entrance(formats.count + 1)
                    .padding(.top, Spacing.xs)
                }
                .padding(.horizontal, Spacing.md)
            }
            .contentMargins(.bottom, Metrics.tabBarClearance, for: .scrollContent)
        }
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            formats = (try? await menuRepository.loadFormats(restaurantId: restaurant.id)) ?? []
        }
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("How are you ordering?")
                .microLabelStyle(restaurant.style.hue)
            Text(restaurant.name)
                .displayXLStyle()
        }
        .entrance(0)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// One order format: hue tile, name, and a one-line "what it is".
private struct FormatCard: View {
    let format: OrderFormat
    let hue: Color

    var body: some View {
        Card {
            HStack(spacing: Spacing.md) {
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .fill(hue.opacity(0.16))
                    .frame(width: 46, height: 46)
                    .overlay {
                        Circle().fill(hue).frame(width: 11, height: 11)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(format.name)
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                    Text(format.blurb)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: Spacing.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.textTertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(format.name). \(format.blurb)")
    }
}

/// The escape hatch — the full flat station list, no guidance. Rendered
/// quieter than the format cards so it reads as "advanced".
private struct BuildYourOwnCard: View {
    var body: some View {
        Card {
            HStack(spacing: Spacing.md) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.textSecondary)
                    .frame(width: 46, height: 46)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                            .overlay {
                                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                                    .strokeBorder(Color.hairline, lineWidth: 1)
                            }
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Build your own")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                    Text("Start from the full station list")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                Spacer(minLength: Spacing.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.textTertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Build your own, start from the full station list")
    }
}
