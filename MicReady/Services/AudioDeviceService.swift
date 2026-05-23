import CoreAudio
import Foundation

struct AudioDeviceService {
    func currentInputDevices() -> [AudioInputDevice] {
        loadInputDevices()
    }

    func activeInputDeviceID(
        selectedInputDeviceID: String,
        availableDevices: [AudioInputDevice]
    ) -> AudioDeviceID? {
        if selectedInputDeviceID != AudioInputDevice.systemDefaultID,
           let selectedDevice = availableDevices.first(where: { $0.id == selectedInputDeviceID }),
           let deviceID = selectedDevice.deviceID {
            return deviceID
        }

        return defaultInputDeviceID()
    }

    func currentDefaultInputDeviceSelectionID() -> String? {
        guard let deviceID = defaultInputDeviceID() else { return nil }
        return deviceUID(for: deviceID) ?? String(deviceID)
    }

    func defaultInputDeviceName() -> String? {
        guard let deviceID = defaultInputDeviceID() else { return nil }
        return deviceName(for: deviceID)
    }

    @discardableResult
    func setDefaultInputDevice(deviceID: AudioDeviceID) -> Bool {
        var targetDeviceID = deviceID
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            size,
            &targetDeviceID
        )

        return status == noErr
    }

    func setInputVolume(deviceID: AudioDeviceID, volume: Float) {
        var volumeValue = volume
        let volumeSize = UInt32(MemoryLayout<Float32>.size)
        let elements: [AudioObjectPropertyElement] = [
            kAudioObjectPropertyElementMain,
            1,
            2
        ]

        for element in elements {
            var address = volumeAddress(element: element)
            guard AudioObjectHasProperty(deviceID, &address) else { continue }
            AudioObjectSetPropertyData(deviceID, &address, 0, nil, volumeSize, &volumeValue)
        }
    }

    func getInputVolume(deviceID: AudioDeviceID) -> Float {
        if let mainVolume = readMicInputVolume(from: deviceID, element: kAudioObjectPropertyElementMain) {
            return mainVolume
        }

        let channelVolumes = [UInt32(1), 2].compactMap { element in
            readMicInputVolume(from: deviceID, element: element)
        }

        guard !channelVolumes.isEmpty else { return 0 }
        let sum = channelVolumes.reduce(0, +)
        return sum / Float(channelVolumes.count)
    }

    private func defaultInputDeviceID() -> AudioDeviceID? {
        var defaultDevice = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &defaultDevice
        )

        guard status == noErr, defaultDevice != AudioDeviceID(0) else { return nil }
        return defaultDevice
    }

    private func loadInputDevices() -> [AudioInputDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let sizeStatus = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        )

        guard sizeStatus == noErr else { return [] }

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = Array(repeating: AudioDeviceID(0), count: count)
        let devicesStatus = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )

        guard devicesStatus == noErr else { return [] }

        return deviceIDs.compactMap { deviceID in
            guard isInputDevice(deviceID),
                  let name = deviceName(for: deviceID),
                  isSelectableInputDevice(name: name),
                  !name.isEmpty else {
                return nil
            }

            return AudioInputDevice(
                id: deviceUID(for: deviceID) ?? String(deviceID),
                name: name,
                deviceID: deviceID
            )
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func isSelectableInputDevice(name: String) -> Bool {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if normalizedName == AudioInputDevice.systemDefaultName.lowercased() {
            return false
        }

        if normalizedName.contains("microsoft teams") {
            return false
        }

        return true
    }

    private func isInputDevice(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        guard AudioObjectHasProperty(deviceID, &address) else { return false }

        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize)
        return status == noErr && dataSize > 0
    }

    private func deviceName(for deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name: CFString?
        var dataSize = UInt32(MemoryLayout<CFString?>.size)
        let status = withUnsafeMutablePointer(to: &name) { pointer in
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, pointer)
        }

        guard status == noErr, let name else { return nil }
        return name as String
    }

    private func deviceUID(for deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var uid: CFString?
        var dataSize = UInt32(MemoryLayout<CFString?>.size)
        let status = withUnsafeMutablePointer(to: &uid) { pointer in
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, pointer)
        }

        guard status == noErr,
              let uid,
              !(uid as String).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return uid as String
    }

    private func volumeAddress(element: AudioObjectPropertyElement) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: element
        )
    }

    private func readMicInputVolume(from device: AudioDeviceID, element: AudioObjectPropertyElement) -> Float? {
        var address = volumeAddress(element: element)
        guard AudioObjectHasProperty(device, &address) else { return nil }

        var volume: Float32 = 0
        var volumeSize = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &volumeSize, &volume)

        guard status == noErr else { return nil }
        return min(max(volume, 0), 1)
    }
}
