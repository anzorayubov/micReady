import AppKit
import Combine
import CoreAudio
import Foundation

final class MicrophoneMonitor: ObservableObject {
    static let shared = MicrophoneMonitor()

    static let supportedTargetVolumeSteps: [Float] = [0.0, 0.25, 0.5, 0.75, 1.0]

    @Published var watchedApps: [WatchedApp] = [] {
        didSet { settingsStore.saveWatchedApps(watchedApps) }
    }
    @Published var isActive = false
    @Published var currentMicVolume: Float = 0
    @Published var lastTriggeredApp: String?
    @Published private(set) var targetMicVolume: Float = 1.0
    @Published private(set) var availableInputDevices: [AudioInputDevice] = []
    @Published private(set) var selectedInputDeviceID = AudioInputDevice.systemDefaultID
    @Published private(set) var customInputDeviceNames: [String: String] = [:]
    @Published private(set) var hiddenInputDeviceIDs: Set<String> = []

    private var timer: Timer?
    private let settingsStore: SettingsStore
    private let audioDeviceService: AudioDeviceService
    private let installedAppsService: InstalledAppsService

    init(
        settingsStore: SettingsStore = SettingsStore(),
        audioDeviceService: AudioDeviceService = AudioDeviceService(),
        installedAppsService: InstalledAppsService = InstalledAppsService()
    ) {
        self.settingsStore = settingsStore
        self.audioDeviceService = audioDeviceService
        self.installedAppsService = installedAppsService

        watchedApps = settingsStore.loadWatchedApps()
        targetMicVolume = snappedVolume(for: settingsStore.loadTargetMicVolume())
        selectedInputDeviceID = settingsStore.loadSelectedInputDeviceID()
        customInputDeviceNames = settingsStore.loadCustomInputDeviceNames()
        hiddenInputDeviceIDs = settingsStore.loadHiddenInputDeviceIDs()
        refreshInputDevices()
        refreshMicInputVolume()
    }

    var visibleInputDevices: [AudioInputDevice] {
        availableInputDevices.filter { device in
            !hiddenInputDeviceIDs.contains(device.id)
        }
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkAndSetMicVolume()
        }
        timer?.fire()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func updateTargetMicVolume(to volume: Float) {
        let normalizedVolume = snappedVolume(for: volume)
        guard targetMicVolume != normalizedVolume else {
            if isActive {
                setMicInputVolume(to: normalizedVolume)
            }
            return
        }

        targetMicVolume = normalizedVolume
        settingsStore.saveTargetMicVolume(normalizedVolume)

        if isActive {
            setMicInputVolume(to: normalizedVolume)
        } else {
            refreshMicInputVolume()
        }
    }

    func selectInputDevice(_ deviceID: String) {
        guard selectedInputDeviceID != deviceID else { return }

        refreshInputDevices()

        guard deviceID == AudioInputDevice.systemDefaultID || !hiddenInputDeviceIDs.contains(deviceID) else {
            return
        }

        if let selectedDevice = availableInputDevices.first(where: { $0.id == deviceID }),
           let audioDeviceID = selectedDevice.deviceID {
            _ = audioDeviceService.setDefaultInputDevice(deviceID: audioDeviceID)
        }

        selectedInputDeviceID = deviceID
        settingsStore.saveSelectedInputDeviceID(deviceID)

        refreshInputDevices()

        if isActive {
            setMicInputVolume(to: targetMicVolume)
        } else {
            refreshMicInputVolume()
        }
    }

    func setMicInputVolume(to volume: Float) {
        guard let device = activeInputDeviceID() else { return }
        audioDeviceService.setInputVolume(deviceID: device, volume: volume)
        refreshMicInputVolume()
    }

    func getMicInputVolume() -> Float {
        guard let device = activeInputDeviceID() else { return 0 }
        return audioDeviceService.getInputVolume(deviceID: device)
    }

    func refreshMicInputVolume() {
        currentMicVolume = getMicInputVolume()
    }

    func canRenameInputDevice(_ device: AudioInputDevice) -> Bool {
        device.id != AudioInputDevice.systemDefaultID
    }

    func canHideInputDevice(_ device: AudioInputDevice) -> Bool {
        device.id != AudioInputDevice.systemDefaultID
    }

    func isInputDeviceHidden(_ device: AudioInputDevice) -> Bool {
        hiddenInputDeviceIDs.contains(device.id)
    }

    func hideInputDevice(_ device: AudioInputDevice) {
        guard canHideInputDevice(device), !hiddenInputDeviceIDs.contains(device.id) else { return }

        hiddenInputDeviceIDs.insert(device.id)
        settingsStore.saveHiddenInputDeviceIDs(hiddenInputDeviceIDs)

        if selectedInputDeviceID == device.id {
            selectInputDevice(fallbackInputDeviceID())
        }
    }

    func showInputDevice(_ device: AudioInputDevice) {
        guard hiddenInputDeviceIDs.remove(device.id) != nil else { return }
        settingsStore.saveHiddenInputDeviceIDs(hiddenInputDeviceIDs)
    }

    func editableInputDeviceName(for device: AudioInputDevice) -> String {
        customInputDeviceNames[device.id] ?? device.name
    }

    func inputDeviceDisplayName(for device: AudioInputDevice) -> String {
        if device.id == AudioInputDevice.systemDefaultID,
           let defaultName = audioDeviceService.defaultInputDeviceName(),
           !defaultName.isEmpty {
            let resolvedDefaultName = customInputDeviceNames[currentDefaultDeviceID() ?? ""] ?? defaultName
            return "\(device.name): \(resolvedDefaultName)"
        }

        return editableInputDeviceName(for: device)
    }

    func renameInputDevice(_ deviceID: String, to newName: String) {
        let normalizedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        if let device = availableInputDevices.first(where: { $0.id == deviceID }),
           normalizedName.isEmpty || normalizedName == device.name {
            customInputDeviceNames.removeValue(forKey: deviceID)
        } else if !normalizedName.isEmpty {
            customInputDeviceNames[deviceID] = normalizedName
        } else {
            customInputDeviceNames.removeValue(forKey: deviceID)
        }

        settingsStore.saveCustomInputDeviceNames(customInputDeviceNames)
    }

    func selectedInputDeviceDisplayName() -> String {
        let selectedDevice = availableInputDevices.first(where: { $0.id == selectedInputDeviceID })
            ?? visibleInputDevices.first
            ?? .systemDefault
        return inputDeviceDisplayName(for: selectedDevice)
    }

    func refreshInputDevices() {
        let devices = audioDeviceService.currentInputDevices()

        if availableInputDevices != devices {
            availableInputDevices = devices
        }

        let resolvedSelectedID: String
        if selectedInputDeviceID == AudioInputDevice.systemDefaultID {
            resolvedSelectedID = fallbackInputDeviceID(in: devices)
        } else if devices.contains(where: { $0.id == selectedInputDeviceID }),
                  !hiddenInputDeviceIDs.contains(selectedInputDeviceID) {
            resolvedSelectedID = selectedInputDeviceID
        } else {
            resolvedSelectedID = fallbackInputDeviceID(in: devices)
        }

        if selectedInputDeviceID != resolvedSelectedID {
            selectedInputDeviceID = resolvedSelectedID
            settingsStore.saveSelectedInputDeviceID(resolvedSelectedID)
        }
    }

    func getInstalledApps() -> [WatchedApp] {
        installedAppsService.getInstalledApps()
    }

    private func checkAndSetMicVolume() {
        refreshInputDevices()

        let runningApps = NSWorkspace.shared.runningApplications
        let runningBundleIDs = Set(runningApps.compactMap { $0.bundleIdentifier })
        let enabledWatchedBundleIDs = watchedApps
            .filter { $0.isEnabled }
            .map { $0.bundleIdentifier }
        let triggered = enabledWatchedBundleIDs.first(where: { runningBundleIDs.contains($0) })

        DispatchQueue.main.async {
            if let triggeredID = triggered {
                let appName = self.watchedApps.first(where: { $0.bundleIdentifier == triggeredID })?.name ?? triggeredID
                self.lastTriggeredApp = appName
                self.isActive = true
                self.setMicInputVolume(to: self.targetMicVolume)
            } else {
                self.lastTriggeredApp = nil
                self.isActive = false
            }
            self.refreshMicInputVolume()
        }
    }

    private func snappedVolume(for volume: Float) -> Float {
        let clampedVolume = min(max(volume, 0), 1)
        return Self.supportedTargetVolumeSteps.min(by: {
            abs($0 - clampedVolume) < abs($1 - clampedVolume)
        }) ?? 1.0
    }

    private func activeInputDeviceID() -> AudioDeviceID? {
        audioDeviceService.activeInputDeviceID(
            selectedInputDeviceID: selectedInputDeviceID,
            availableDevices: availableInputDevices
        )
    }

    private func currentDefaultDeviceID() -> String? {
        audioDeviceService.currentDefaultInputDeviceSelectionID()
    }

    private func fallbackInputDeviceID(in devices: [AudioInputDevice]? = nil) -> String {
        let inputDevices = devices ?? availableInputDevices
        return inputDevices.first(where: { !hiddenInputDeviceIDs.contains($0.id) })?.id
            ?? AudioInputDevice.systemDefaultID
    }
}
