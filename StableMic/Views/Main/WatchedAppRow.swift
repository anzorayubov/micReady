import AppKit
import SwiftUI

struct WatchedAppRow: View {
    @EnvironmentObject var settings: AppSettings
    @Binding var app: WatchedApp
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let icon = AppIconProvider.icon(for: app.bundleIdentifier) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 28, height: 28)
            } else {
                Image(systemName: "app.fill")
                    .frame(width: 28, height: 28)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13))
            }

            Spacer()

            Toggle("", isOn: $app.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help(settings.text(.removeApplication))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label(settings.text(.removeApplication), systemImage: "trash")
            }
        }
    }
}
