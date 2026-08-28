import Foundation

struct WatchedApp: Identifiable, Codable, Hashable {
    var id: String { bundleIdentifier }
    var name: String
    var bundleIdentifier: String
    var isEnabled: Bool
}
