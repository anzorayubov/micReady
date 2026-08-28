import CoreAudio
import Foundation

struct AudioInputDevice: Identifiable, Hashable {
    let id: String
    let name: String
    let deviceID: AudioDeviceID?

    static let systemDefaultID = "system-default"
    static let systemDefaultName = "System Default"

    static let systemDefault = AudioInputDevice(
        id: systemDefaultID,
        name: systemDefaultName,
        deviceID: nil
    )
}
