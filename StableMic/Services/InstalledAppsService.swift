import Foundation

struct InstalledAppsService {
    func getInstalledApps() -> [WatchedApp] {
        let fileManager = FileManager.default
        let appDirectories = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
        ]
        var appsByBundleIdentifier: [String: WatchedApp] = [:]

        for directory in appDirectories {
            guard let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for case let appURL as URL in enumerator {
                guard appURL.pathExtension.caseInsensitiveCompare("app") == .orderedSame else { continue }
                enumerator.skipDescendants()

                guard let bundle = Bundle(url: appURL),
                      let bundleID = bundle.bundleIdentifier,
                      appsByBundleIdentifier[bundleID] == nil else {
                    continue
                }

                let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? appURL.deletingPathExtension().lastPathComponent
                appsByBundleIdentifier[bundleID] = WatchedApp(
                    name: name,
                    bundleIdentifier: bundleID,
                    isEnabled: false
                )
            }
        }

        return appsByBundleIdentifier.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}
