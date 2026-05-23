import Foundation

final class SettingsStore {
    private let defaults: UserDefaults
    private let watchedAppsKey = "watchedApps"
    private let targetMicVolumeKey = "targetMicVolume"
    private let selectedInputDeviceKey = "selectedInputDeviceID"
    private let customInputDeviceNamesKey = "customInputDeviceNames"
    private let hiddenInputDeviceIDsKey = "hiddenInputDeviceIDs"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadWatchedApps() -> [WatchedApp] {
        guard let data = defaults.data(forKey: watchedAppsKey),
              let apps = try? JSONDecoder().decode([WatchedApp].self, from: data) else {
            return defaultWatchedApps()
        }

        return apps
    }

    func saveWatchedApps(_ watchedApps: [WatchedApp]) {
        if let data = try? JSONEncoder().encode(watchedApps) {
            defaults.set(data, forKey: watchedAppsKey)
        }
    }

    func loadTargetMicVolume(defaultValue: Float = 1.0) -> Float {
        if defaults.object(forKey: targetMicVolumeKey) == nil {
            return defaultValue
        }

        return defaults.float(forKey: targetMicVolumeKey)
    }

    func saveTargetMicVolume(_ volume: Float) {
        defaults.set(volume, forKey: targetMicVolumeKey)
    }

    func loadSelectedInputDeviceID() -> String {
        defaults.string(forKey: selectedInputDeviceKey) ?? AudioInputDevice.systemDefaultID
    }

    func saveSelectedInputDeviceID(_ deviceID: String) {
        defaults.set(deviceID, forKey: selectedInputDeviceKey)
    }

    func loadCustomInputDeviceNames() -> [String: String] {
        guard let data = defaults.data(forKey: customInputDeviceNamesKey),
              let names = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }

        return names
    }

    func saveCustomInputDeviceNames(_ names: [String: String]) {
        if let data = try? JSONEncoder().encode(names) {
            defaults.set(data, forKey: customInputDeviceNamesKey)
        }
    }

    func loadHiddenInputDeviceIDs() -> Set<String> {
        guard let data = defaults.data(forKey: hiddenInputDeviceIDsKey),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }

        return Set(ids)
    }

    func saveHiddenInputDeviceIDs(_ ids: Set<String>) {
        let storedIDs = ids
            .filter { $0 != AudioInputDevice.systemDefaultID }
            .sorted()

        if let data = try? JSONEncoder().encode(storedIDs) {
            defaults.set(data, forKey: hiddenInputDeviceIDsKey)
        }
    }

    private func defaultWatchedApps() -> [WatchedApp] {
        [
            WatchedApp(name: "Zoom", bundleIdentifier: "us.zoom.xos", isEnabled: true),
            WatchedApp(name: "Microsoft Teams", bundleIdentifier: "com.microsoft.teams", isEnabled: true),
            WatchedApp(name: "Google Chrome", bundleIdentifier: "com.google.Chrome", isEnabled: false),
        ]
    }
}
