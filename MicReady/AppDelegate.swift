import AppKit
import SwiftUI
import CoreAudio
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var monitor: MicrophoneMonitor?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 540)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(MicrophoneMonitor.shared)
                .environmentObject(AppSettings.shared)
        )
        self.popover = popover

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = makeStatusImage(isActive: MicrophoneMonitor.shared.isActive)
            button.action = #selector(togglePopover)
            button.target = self
        }
        self.statusItem = statusItem

        MicrophoneMonitor.shared.$isActive
            .receive(on: RunLoop.main)
            .sink { [weak self] isActive in
                self?.statusItem?.button?.image = self?.makeStatusImage(isActive: isActive)
            }
            .store(in: &cancellables)

        MicrophoneMonitor.shared.startMonitoring()
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                DispatchQueue.main.async {
                    NSApp.activate(ignoringOtherApps: true)
                    popover.contentViewController?.view.window?.makeKey()
                    popover.contentViewController?.view.window?.orderFrontRegardless()
                }
            }
        }
    }

    private func makeStatusImage(isActive: Bool) -> NSImage? {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)

        image.lockFocus()
        defer { image.unlockFocus() }

        let micConfiguration = NSImage.SymbolConfiguration(
            paletteColors: [.secondaryLabelColor]
        )
        if let micImage = NSImage(
            systemSymbolName: "mic.fill",
            accessibilityDescription: "MicReady"
        )?.withSymbolConfiguration(micConfiguration) {
            micImage.size = size
            micImage.draw(
                in: NSRect(origin: .zero, size: size),
                from: .zero,
                operation: .sourceOver,
                fraction: 1
            )
        }

        if isActive {
            let dotRect = NSRect(x: size.width - 7, y: size.height - 7, width: 5, height: 5)
            NSColor.systemGreen.setFill()
            NSBezierPath(ovalIn: dotRect).fill()

            NSColor.controlBackgroundColor.setStroke()
            let border = NSBezierPath(ovalIn: dotRect.insetBy(dx: -0.75, dy: -0.75))
            border.lineWidth = 1.5
            border.stroke()
        }

        image.isTemplate = false
        return image
    }
}
