import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: MicrophoneMonitor
    @EnvironmentObject var settings: AppSettings
    @State private var showAppPicker = false
    @State private var currentScreen: Screen = .main

    enum Screen {
        case main
        case settings
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(currentScreen: currentScreen) {
                currentScreen = .main
            } openSettings: {
                currentScreen = .settings
            }

            Divider()

            Group {
                if currentScreen == .main {
                    mainContentView
                } else {
                    SettingsView()
                }
            }
        }
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showAppPicker) {
            AppPickerView()
                .environmentObject(monitor)
                .environmentObject(settings)
        }
    }

    private var mainContentView: some View {
        Group {
            if monitor.isActive || monitor.lastTriggeredApp != nil {
                StatusView()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                Divider()
            }

            VolumeControlView()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            if monitor.watchedApps.isEmpty {
                EmptyStateView()
            } else {
                WatchedAppsListView()
            }

            Divider()

            FooterView(showAppPicker: $showAppPicker)
        }
    }
}
