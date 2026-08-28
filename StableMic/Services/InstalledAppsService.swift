import AppKit
import Foundation

struct InstalledAppsService {
    func getInstalledApps() -> [WatchedApp] {
        let fileManager = FileManager.default
        let appDirectories = ["/Applications", "\(NSHomeDirectory())/Applications"]
        var apps: [WatchedApp] = []

        for directory in appDirectories {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: directory) else {
                continue
            }

            for item in contents where item.hasSuffix(".app") {
                let fullPath = "\(directory)/\(item)"
                let plistPath = "\(fullPath)/Contents/Info.plist"
                if let plist = NSDictionary(contentsOfFile: plistPath),
                   let bundleID = plist["CFBundleIdentifier"] as? String {
                    let name = (plist["CFBundleDisplayName"] as? String)
                        ?? (plist["CFBundleName"] as? String)
                        ?? item.replacingOccurrences(of: ".app", with: "")
                    let app = WatchedApp(name: name, bundleIdentifier: bundleID, isEnabled: false)
                    if !apps.contains(where: { $0.bundleIdentifier == bundleID }) {
                        apps.append(app)
                    }
                }
            }
        }

        return apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
}
