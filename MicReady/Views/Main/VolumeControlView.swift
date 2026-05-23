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
                        withAnimation(.easeInOut(duration: 0.2)) {
                            inputDeviceEditing.toggleEditing()
                        }
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
        static let rowHeight: CGFloat = 40
        static let nameHeight: CGFloat = 28
    }

    @EnvironmentObject var monitor: MicrophoneMonitor
    @EnvironmentObject var settings: AppSettings

    let device: AudioInputDevice
    let isEditingEnabled: Bool

    @State private var draftName = ""
    @State private var isHovered = false
    @State private var editProgress: CGFloat = 0

    var body: some View {
        let isHidden = monitor.isInputDeviceHidden(device)

        HStack(spacing: 8) {
            selectionIcon

            nameContent

            if isEditingEnabled, monitor.canHideInputDevice(device) {
                hiddenButton
            }
        }
        .opacity(isHidden ? 0.55 : 1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .frame(height: Layout.rowHeight)
        .background(isHovered ? Color(NSColor.quaternaryLabelColor).opacity(0.14) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isEditingEnabled else { return }
            monitor.selectInputDevice(device.id)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onChange(of: monitor.customInputDeviceNames) { _ in
            guard !isEditingEnabled else { return }
            draftName = monitor.inputDeviceDisplayName(for: device)
        }
        .onChange(of: isEditingEnabled) { isEditing in
            withAnimation(.easeInOut(duration: 0.2)) {
                editProgress = isEditing ? 1 : 0
            }

            if isEditing {
                draftName = monitor.editableInputDeviceName(for: device)
            } else {
                commitEditing()
                draftName = monitor.inputDeviceDisplayName(for: device)
            }
        }
        .onAppear {
            editProgress = isEditingEnabled ? 1 : 0
            draftName = isEditingEnabled
                ? monitor.editableInputDeviceName(for: device)
                : monitor.inputDeviceDisplayName(for: device)
        }
        .animation(.easeInOut(duration: 0.2), value: isEditingEnabled)
    }

    private var nameContent: some View {
        let canRename = monitor.canRenameInputDevice(device)

        return Group {
            if isEditingEnabled {
                TextField(
                    settings.text(.renameMicrophonePlaceholder),
                    text: $draftName
                )
                .textFieldStyle(.plain)
                .disabled(!canRename)
                .onSubmit {
                    commitEditing()
                }
            } else {
                Text(draftName)
                    .lineLimit(1)
            }
        }
        .font(.system(size: 14))
        .foregroundColor(!isEditingEnabled || canRename ? .primary : .secondary)
        .padding(.horizontal, editProgress * 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Layout.nameHeight)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(canRename ? Color(NSColor.textBackgroundColor) : Color(NSColor.controlBackgroundColor))
                .opacity(editProgress)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(
                    canRename ? Color.accentColor.opacity(0.35) : Color(NSColor.separatorColor).opacity(0.7),
                    lineWidth: 1
                )
                .opacity(editProgress)
        )
        .animation(.easeInOut(duration: 0.2), value: editProgress)
    }

    private var hiddenButton: some View {
        let isHidden = monitor.isInputDeviceHidden(device)

        return Button {
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
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    private var selectionIcon: some View {
        Image(systemName: monitor.selectedInputDeviceID == device.id ? "largecircle.fill.circle" : "circle")
            .font(.system(size: 14))
            .foregroundColor(monitor.selectedInputDeviceID == device.id ? .accentColor : .secondary)
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
