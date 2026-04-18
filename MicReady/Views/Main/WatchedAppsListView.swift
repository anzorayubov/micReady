import SwiftUI

struct WatchedAppsListView: View {
    @EnvironmentObject var monitor: MicrophoneMonitor

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach($monitor.watchedApps) { $app in
                    WatchedAppRow(app: $app) {
                        monitor.watchedApps.removeAll { $0.bundleIdentifier == app.bundleIdentifier }
                    }

                    if app.bundleIdentifier != monitor.watchedApps.last?.bundleIdentifier {
                        Divider().padding(.leading, 44)
                    }
                }
            }
        }
        .frame(maxHeight: 260)
    }
}
