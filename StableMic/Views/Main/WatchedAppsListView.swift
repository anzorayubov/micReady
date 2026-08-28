import SwiftUI

struct WatchedAppsListView: View {
    @EnvironmentObject var monitor: MicrophoneMonitor
    private let maxVisibleAppsWithoutScroll = 5

    var body: some View {
        if monitor.watchedApps.count > maxVisibleAppsWithoutScroll {
            ScrollView {
                appsList
            }
            .frame(maxHeight: 260)
        } else {
            appsList
        }
    }

    private var appsList: some View {
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
}
