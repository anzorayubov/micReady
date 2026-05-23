import SwiftUI

struct VolumeControlView: View {
    @EnvironmentObject var monitor: MicrophoneMonitor
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var inputDeviceEditing: InputDeviceEditingController

    var body: some View {
        let inputDevices = inputDeviceEditing.isEditing ? monitor.availableInputDevices : monitor.visibleInputDevices

        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(settings.text(.microphoneSource))
                        .font(.system(size: 12, weight: .semibold))

                    Spacer()

                    Button {
                        inputDeviceEditing.toggleEditing()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(inputDeviceEditing.isEditing ? .accentColor : .secondary)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(settings.text(.renameMicrophone))
                }

                VStack(spacing: 0) {
                    ForEach(inputDevices) { device in
                        InputDeviceRow(
                            device: device,
                            isEditingEnabled: inputDeviceEditing.isEditing
                        )
                            .environmentObject(monitor)
                            .environmentObject(settings)

                        if device.id != inputDevices.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            HStack {
                Text(settings.text(.autoMaintainVolume))
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text("\(Int(monitor.targetMicVolume * 100))%")
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
            }

            Slider(
                value: Binding(
                    get: { Double(monitor.targetMicVolume) },
                    set: { monitor.updateTargetMicVolume(to: Float($0)) }
                ),
                in: 0...1
            )
            .tint(.accentColor)

            HStack {
                ForEach(MicrophoneMonitor.supportedTargetVolumeSteps, id: \.self) { step in
                    Text("\(Int(step * 100))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .monospacedDigit()
                }
            }
        }
    }
}

private struct InputDeviceRow: View {
    private enum Layout {
        static let rowHeight: CGFloat = 34
        static let nameHeight: CGFloat = 22
    }

    @EnvironmentObject var monitor: MicrophoneMonitor
    @EnvironmentObject var settings: AppSettings

    let device: AudioInputDevice
    let isEditingEnabled: Bool

    @State private var draftName = ""
    @State private var isHovered = false

    var body: some View {
        let isHidden = monitor.isInputDeviceHidden(device)

        Group {
            if isEditingEnabled {
                HStack(spacing: 8) {
                    Image(systemName: monitor.selectedInputDeviceID == device.id ? "largecircle.fill.circle" : "circle")
                        .font(.system(size: 14))
                        .foregroundColor(monitor.selectedInputDeviceID == device.id ? .accentColor : .secondary)

                    nameContent

                    Spacer(minLength: 0)

                    if monitor.canHideInputDevice(device) {
                        Button {
                            toggleHidden()
                        } label: {
                            Image(systemName: isHidden ? "eye.slash" : "eye")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(isHidden ? .secondary : .accentColor)
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(settings.text(isHidden ? .showMicrophoneSource : .hideMicrophoneSource))
                        .help(settings.text(isHidden ? .showMicrophoneSource : .hideMicrophoneSource))
                    }
                }
                .opacity(isHidden ? 0.55 : 1)
            } else {
                Button {
                    monitor.selectInputDevice(device.id)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: monitor.selectedInputDeviceID == device.id ? "largecircle.fill.circle" : "circle")
                            .font(.system(size: 14))
                            .foregroundColor(monitor.selectedInputDeviceID == device.id ? .accentColor : .secondary)

                        nameContent
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .frame(height: Layout.rowHeight)
        .background(isHovered ? Color(NSColor.quaternaryLabelColor).opacity(0.14) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onChange(of: monitor.customInputDeviceNames) { _ in
            guard !isEditingEnabled else { return }
            draftName = monitor.editableInputDeviceName(for: device)
        }
        .onChange(of: isEditingEnabled) { isEditing in
            if isEditing {
                draftName = monitor.editableInputDeviceName(for: device)
            } else {
                commitEditing()
            }
        }
        .onAppear {
            draftName = monitor.editableInputDeviceName(for: device)
        }
    }

    @ViewBuilder
    private var nameContent: some View {
        if isEditingEnabled {
            TextField(
                settings.text(.renameMicrophonePlaceholder),
                text: $draftName
            )
            .textFieldStyle(.plain)
            .font(.system(size: 14))
            .frame(height: Layout.nameHeight)
            .disabled(!monitor.canRenameInputDevice(device))
            .onSubmit {
                commitEditing()
            }
        } else {
            Text(monitor.inputDeviceDisplayName(for: device))
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: Layout.nameHeight)
                .lineLimit(1)
        }
    }

    private func commitEditing() {
        guard monitor.canRenameInputDevice(device) else { return }

        monitor.renameInputDevice(device.id, to: draftName)
        draftName = monitor.editableInputDeviceName(for: device)
    }

    private func toggleHidden() {
        commitEditing()

        if monitor.isInputDeviceHidden(device) {
            monitor.showInputDevice(device)
        } else {
            monitor.hideInputDevice(device)
        }
    }
}
