import Foundation

/// What the configure sheet is currently opened on. Carries the tray line id
/// when reopening an existing order so committing edits that line rather than
/// adding a second one.
struct ConfigurationTarget: Identifiable, Hashable {
    let item: MenuItem
    let category: MenuCategory
    var lineItemId: UUID?
    var configuration: ItemConfiguration = .unchanged

    var id: String { "\(item.id)#\(lineItemId?.uuidString ?? "new")" }

    // Identity is the id — two targets for the same item and tray line are the
    // same destination, whatever configuration is being edited.
    static func == (lhs: ConfigurationTarget, rhs: ConfigurationTarget) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
