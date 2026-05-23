import SwiftUI

struct VolumeControlView: View {
    @EnvironmentObject var monitor: MicrophoneMonitor
    @EnvironmentObject var settings: AppSettings
    @State private var isRenamingDevices = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(settings.text(.microphoneSource))
                        .font(.system(size: 12, weight: .semibold))

                    Spacer()

                    Button {
                        isRenamingDevices.toggle()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isRenamingDevices ? .accentColor : .secondary)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(settings.text(.renameMicrophone))
                }

                VStack(spacing: 0) {
                    ForEach(monitor.availableInputDevices) { device in
                        InputDeviceRow(
                            device: device,
                            isEditingEnabled: isRenamingDevices
                        )
                            .environmentObject(monitor)
                            .environmentObject(settings)

                        if device.id != monitor.availableInputDevices.last?.id {
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
    @EnvironmentObject var monitor: MicrophoneMonitor
    @EnvironmentObject var settings: AppSettings

    let device: AudioInputDevice
    let isEditingEnabled: Bool

    @State private var draftName = ""
    @State private var isHovered = false

    var body: some View {
        Group {
            if isEditingEnabled {
                HStack(spacing: 8) {
                    Image(systemName: monitor.selectedInputDeviceID == device.id ? "largecircle.fill.circle" : "circle")
                        .font(.system(size: 12))
                        .foregroundColor(monitor.selectedInputDeviceID == device.id ? .accentColor : .secondary)

                    nameContent
                }
            } else {
                Button {
                    monitor.selectInputDevice(device.id)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: monitor.selectedInputDeviceID == device.id ? "largecircle.fill.circle" : "circle")
                            .font(.system(size: 12))
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
        .padding(.vertical, 8)
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
            .font(.system(size: 12))
            .onSubmit {
                commitEditing()
            }
        } else {
            Text(monitor.inputDeviceDisplayName(for: device))
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
        }
    }

    private func commitEditing() {
        guard monitor.canRenameInputDevice(device) else { return }

        monitor.renameInputDevice(device.id, to: draftName)
        draftName = monitor.editableInputDeviceName(for: device)
    }
}
