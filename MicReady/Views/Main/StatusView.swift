import SwiftUI

struct StatusView: View {
    @EnvironmentObject var monitor: MicrophoneMonitor
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if monitor.isActive {
                Text(settings.text(.statusActive))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
            }
            if let app = monitor.lastTriggeredApp {
                Text(settings.text(.statusTriggered(app)))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
}
