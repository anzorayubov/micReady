import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var inputDeviceEditing: InputDeviceEditingController
    let onClose: () -> Void
    @State private var currentScreen: Screen = .main

    enum Screen {
        case main
        case settings
    }

    var body: some View {
        VStack(spacing: 0) {
            if currentScreen == .main {
                mainContentView

                Divider()

                MainFooterView {
                    currentScreen = .settings
                }
            } else {
                HeaderView {
                    currentScreen = .main
                }

                Divider()

                SettingsView()
            }
        }
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
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
        .onExitCommand(perform: onClose)
    }

    private var mainContentView: some View {
        VolumeControlView()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
}

private struct MainFooterView: View {
    @EnvironmentObject var settings: AppSettings

    let openSettings: () -> Void

    var body: some View {
        HStack {
            Button(action: openSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(settings.text(.settingsTitle))
            .help(settings.text(.settingsTitle))

            Spacer()

            Button(action: { NSApp.terminate(nil) }) {
                Text(settings.text(.quit))
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
