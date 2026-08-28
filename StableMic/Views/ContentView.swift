import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: MicrophoneMonitor
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var inputDeviceEditing: InputDeviceEditingController
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
        .background(
            CommandShortcutHandler(
                onCommandE: {
                    guard currentScreen == .main else { return false }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        inputDeviceEditing.enableEditing()
                    }
                    return true
                },
                onCommandS: {
                    guard inputDeviceEditing.isEditing else { return false }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        inputDeviceEditing.saveEditing()
                    }
                    return true
                }
            )
        )
    }

    private var mainContentView: some View {
        Group {
            if monitor.isActive || monitor.lastTriggeredApp != nil {
                StatusView()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                Divider()
            }

            VolumeControlView()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            HStack {
                Text(settings.text(.watchedApplications))
                    .font(.system(size: 12, weight: .semibold))

                Spacer()

                Button(action: { showAppPicker = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.text(.addApplication))
                .help(settings.text(.addApplication))
            }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

            Group {
                if monitor.watchedApps.isEmpty {
                    EmptyStateView()
                } else {
                    WatchedAppsListView()
                }
            }
            .padding(.bottom, 6)

        }
    }
}

private struct CommandShortcutHandler: NSViewRepresentable {
    private enum KeyCode {
        static let s: UInt16 = 1
        static let e: UInt16 = 14
    }

    let onCommandE: () -> Bool
    let onCommandS: () -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(onCommandE: onCommandE, onCommandS: onCommandS)
    }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.installMonitor()
        return NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onCommandE = onCommandE
        context.coordinator.onCommandS = onCommandS
    }

    final class Coordinator {
        var onCommandE: () -> Bool
        var onCommandS: () -> Bool
        private var eventMonitor: Any?

        init(onCommandE: @escaping () -> Bool, onCommandS: @escaping () -> Bool) {
            self.onCommandE = onCommandE
            self.onCommandS = onCommandS
        }

        deinit {
            if let eventMonitor {
                NSEvent.removeMonitor(eventMonitor)
            }
        }

        func installMonitor() {
            guard eventMonitor == nil else { return }

            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self,
                      event.modifierFlags
                        .intersection(.deviceIndependentFlagsMask)
                        .contains(.command)
                else {
                    return event
                }

                switch event.keyCode {
                case KeyCode.e:
                    return self.onCommandE() ? nil : event
                case KeyCode.s:
                    return self.onCommandS() ? nil : event
                default:
                    return event
                }
            }
        }
    }
}
