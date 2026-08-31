import SwiftUI

/// "Which restaurant should Loadout add next?"
///
/// There is no backend, so this composes a mail draft rather than pretending to
/// submit. That's the honest shape: the user can see exactly what's being sent
/// and to whom, and nothing leaves the device unless they hit send in Mail.
struct RestaurantRequestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var name = ""
    @State private var note = ""
    @State private var mailFailed = false
    @FocusState private var focus: Field?

    private enum Field: Hashable { case name, note }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("Every menu in Loadout is checked by hand against what the restaurant publishes, so they go in one at a time. Tell me which one you want and it goes on the list.")
                        .font(.appBody)
                        .foregroundStyle(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Restaurant").microLabelStyle()
                        field("e.g. Sweetgreen", text: $name, field: .name)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Anything else (optional)").microLabelStyle()
                        field("What you'd order there", text: $note, field: .note, lines: 3)
                    }

                    Text("This opens a pre-written email. Nothing is sent until you send it.")
                        .font(.appCaption)
                        .foregroundStyle(.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.md)
            }
            .background(Backdrop())
            .navigationTitle("Request a restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Send request") { send() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(trimmedName.isEmpty)
                    .opacity(trimmedName.isEmpty ? 0.5 : 1)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(.ultraThinMaterial)
            }
            .alert("Couldn't open Mail", isPresented: $mailFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Send the name to \(IndieLinks.feedbackEmail) and it'll get there just the same.")
            }
        }
        .onAppear { focus = .name }
    }

    private func field(
        _ prompt: String, text: Binding<String>, field: Field, lines: Int = 1
    ) -> some View {
        TextField(prompt, text: text, axis: lines > 1 ? .vertical : .horizontal)
            .lineLimit(lines > 1 ? lines...lines + 2 : 1...1)
            .font(.appBody)
            .foregroundStyle(.textPrimary)
            .focused($focus, equals: field)
            .submitLabel(lines > 1 ? .return : .next)
            .onSubmit { if field == .name { focus = .note } }
            .padding(Spacing.sm + Spacing.xs)
            .background {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .strokeBorder(Color.hairline, lineWidth: 1)
                    )
            }
    }

    private func send() {
        guard let url = IndieLinks.restaurantRequest(trimmedName, note: note) else {
            mailFailed = true
            return
        }
        Haptics.success()
        openURL(url) { opened in
            if opened { dismiss() } else { mailFailed = true }
        }
    }
}
