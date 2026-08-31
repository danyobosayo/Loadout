import Foundation

/// Every outward-facing address in one place.
///
/// These are the only strings in the app that point at something the developer
/// owns rather than something a restaurant publishes, so they live together
/// instead of being scattered through view code where a stale URL hides.
///
/// **`appStoreId` is a placeholder until App Store Connect exists.** Nothing
/// here guesses at it — the review paths check `isPublished` and fall back to
/// the system's own review prompt rather than opening a dead App Store link.
nonisolated enum IndieLinks {
    /// Filled in once the app has a listing. Until then every App Store link is
    /// suppressed rather than pointed somewhere hopeful.
    static let appStoreId: String? = nil

    /// Where feedback goes today. A web page with a forum is the eventual plan;
    /// until it exists, mail is the honest route, because it actually arrives.
    static let feedbackEmail = "sungsu.kim04@gmail.com"

    /// The eventual loadout site. Nil keeps the Settings row hidden entirely —
    /// better than shipping a button that 404s.
    static let websiteURL: URL? = nil

    static var isPublished: Bool { appStoreId != nil }

    /// Deep link to the App Store's write-a-review sheet. Nil before launch.
    static var writeReviewURL: URL? {
        guard let appStoreId else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreId)?action=write-review")
    }

    /// A pre-addressed mail draft. Percent-encoding is applied to the subject
    /// and body, not the address, so an apostrophe in a restaurant name ("Raising
    /// Cane's") doesn't truncate the message.
    static func mail(subject: String, body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }

    static func restaurantRequest(_ name: String, note: String) -> URL? {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        var body = "I'd love to see \(name) in Loadout."
        if !trimmedNote.isEmpty {
            body += "\n\n\(trimmedNote)"
        }
        body += "\n\n— sent from Loadout \(appVersion)"
        return mail(subject: "Restaurant request: \(name)", body: body)
    }

    static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}
