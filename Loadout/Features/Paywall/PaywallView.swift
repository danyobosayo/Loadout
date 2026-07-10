import SwiftUI
import StoreKit

/// Loadout Pro paywall — the targeting layer's upsell. Presented when a free
/// user reaches a Pro entry point; dismisses itself the moment `isPro` flips.
struct PaywallView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss
    @State private var purchasingID: String?

    private struct Feature: Identifiable {
        let id = UUID(); let icon: String; let title: String; let detail: String
    }
    private let features = [
        Feature(icon: "target", title: "Daily macro targets",
                detail: "Calculate them from your goal, or paste your own."),
        Feature(icon: "gauge.with.needle", title: "Budget Mode",
                detail: "See how each meal fits your day as you build."),
        Feature(icon: "heart.text.square", title: "Apple Health",
                detail: "Pull today's food so it knows what you have left."),
        Feature(icon: "wand.and.stars", title: "Fit my macros",
                detail: "Auto-build a meal that hits your remaining budget."),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Backdrop(tint: .volt)
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        header
                        VStack(spacing: Spacing.sm) {
                            ForEach(features) { featureRow($0) }
                        }
                        purchaseSection
                        Button("Restore purchases") { Task { await pro.restore() } }
                            .buttonStyle(.ghost)
                        disclaimer
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.textSecondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .presentationBackground(Color.void)
        .task { await pro.refresh() }
        .onChange(of: pro.isPro) { _, isPro in if isPro { dismiss() } }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Loadout Pro").microLabelStyle(.volt)
            Text("Hit your macros,\nevery meal out.")
                .font(.displayTitle)
                .foregroundStyle(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, Spacing.sm)
    }

    private func featureRow(_ f: Feature) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: f.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.volt)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.volt.opacity(0.12)))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(f.title).font(.appHeadline).foregroundStyle(.textPrimary)
                Text(f.detail).font(.appCaption).foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var purchaseSection: some View {
        if pro.products.isEmpty {
            Text(pro.isLoading ? "Loading options…" : "Purchasing isn't available right now.")
                .font(.appCaption)
                .foregroundStyle(.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, Spacing.md)
        } else {
            VStack(spacing: Spacing.sm) {
                ForEach(pro.products, id: \.id) { product in
                    productButton(product, hero: product.id == ProStore.lifetimeID)
                }
            }
        }
    }

    private func productButton(_ product: Product, hero: Bool) -> some View {
        Button {
            purchasingID = product.id
            Task {
                defer { purchasingID = nil }
                _ = try? await pro.purchase(product)   // onChange(isPro) dismisses on success
            }
        } label: {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName).font(.appHeadline).foregroundStyle(.textPrimary)
                    Text(periodLabel(product)).font(.appCaption).foregroundStyle(.textSecondary)
                }
                Spacer()
                if purchasingID == product.id {
                    ProgressView().tint(.volt)
                } else {
                    Text(product.displayPrice)
                        .font(.numeral)
                        .foregroundStyle(hero ? Color.void : .textPrimary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs + 2)
                        .background(Capsule().fill(hero ? Color.volt : Color.white.opacity(0.06)))
                }
            }
        }
        .buttonStyle(.pressable)
        .disabled(purchasingID != nil)
        .padding(Spacing.md)
        .background {
            let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
            shape.fill(Color.surface)
                .overlay(shape.strokeBorder(hero ? Color.volt : Color.hairline, lineWidth: hero ? 1.5 : 1))
        }
    }

    private func periodLabel(_ product: Product) -> String {
        guard let sub = product.subscription else { return "One-time — yours forever" }
        switch sub.subscriptionPeriod.unit {
        case .month: return "per month"
        case .year: return "per year — best value"
        default: return ""
        }
    }

    private var disclaimer: some View {
        Text("Subscriptions renew until cancelled in Settings. A one-time purchase never expires. Prices shown are for your region.")
            .font(.appCaption)
            .foregroundStyle(.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
