import Combine
import CoreAudio
import Foundation

final class MicrophoneMonitor: ObservableObject {
    static let shared = MicrophoneMonitor()

    static let targetVolumeStep: Float = 0.05

    @Published private(set) var isActive = false
    @Published var currentMicVolume: Float = 0
    @Published private(set) var targetMicVolume: Float = 1.0
    @Published private(set) var availableInputDevices: [AudioInputDevice] = []
    @Published private(set) var selectedInputDeviceID = AudioInputDevice.systemDefaultID
    @Published private(set) var customInputDeviceNames: [String: String] = [:]
    @Published private(set) var hiddenInputDeviceIDs: Set<String> = []
    @Published private(set) var inputDeviceSwitchErrorID: String?

    private var timer: Timer?
    private var inputDeviceSwitchErrorResetID: UUID?
    private let settingsStore: SettingsStore
    private let audioDeviceService: AudioDeviceService

    init(
        settingsStore: SettingsStore = SettingsStore(),
        audioDeviceService: AudioDeviceService = AudioDeviceService()
    ) {
        self.settingsStore = settingsStore
        self.audioDeviceService = audioDeviceService

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
        guard timer == nil else { return }

        isActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.enforceTargetMicVolume()
        }
        timer?.fire()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isActive = false
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

        if deviceID != AudioInputDevice.systemDefaultID {
            guard let selectedDevice = availableInputDevices.first(where: { $0.id == deviceID }),
                  let audioDeviceID = selectedDevice.deviceID else {
                showInputDeviceSwitchError(for: deviceID)
                return
            }

            guard audioDeviceService.setDefaultInputDevice(deviceID: audioDeviceID) else {
                showInputDeviceSwitchError(for: deviceID)
                return
            }
        }

        clearInputDeviceSwitchError()
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

    private func enforceTargetMicVolume() {
        refreshInputDevices()
        setMicInputVolume(to: targetMicVolume)
    }

    private func snappedVolume(for volume: Float) -> Float {
        let clampedVolume = min(max(volume, 0), 1)
        let snappedVolume = (clampedVolume / Self.targetVolumeStep).rounded() * Self.targetVolumeStep
        return min(max(snappedVolume, 0), 1)
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

    private func showInputDeviceSwitchError(for deviceID: String) {
        let resetID = UUID()
        inputDeviceSwitchErrorResetID = resetID
        inputDeviceSwitchErrorID = deviceID

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard self?.inputDeviceSwitchErrorResetID == resetID else { return }
            self?.clearInputDeviceSwitchError()
        }
    }

    private func clearInputDeviceSwitchError() {
        inputDeviceSwitchErrorResetID = nil
        inputDeviceSwitchErrorID = nil
    }

    private func fallbackInputDeviceID(in devices: [AudioInputDevice]? = nil) -> String {
        let inputDevices = devices ?? availableInputDevices
        return inputDevices.first(where: { !hiddenInputDeviceIDs.contains($0.id) })?.id
            ?? AudioInputDevice.systemDefaultID
    }
}
