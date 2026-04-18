import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var monitor: MicrophoneMonitor
    @EnvironmentObject var settings: AppSettings

    let currentScreen: ContentView.Screen
    let goBack: () -> Void
    let openSettings: () -> Void

    var body: some View {
        HStack {
            if currentScreen == .settings {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Text(settings.text(.settingsTitle))
                    .font(.system(size: 14, weight: .semibold))
            } else {
                Image(systemName: "mic.fill")
                    .foregroundColor(monitor.isActive ? .green : .secondary)
                    .font(.system(size: 14, weight: .semibold))
                Text("MicReady")
                    .font(.system(size: 14, weight: .semibold))
            }

            Spacer()

            if currentScreen == .main {
                Button(action: openSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.text(.settingsTitle))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
