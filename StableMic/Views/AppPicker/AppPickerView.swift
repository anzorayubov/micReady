import AppKit
import SwiftUI

struct AppPickerView: View {
    @EnvironmentObject var monitor: MicrophoneMonitor
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    @State private var installedApps: [WatchedApp] = []
    @State private var searchText = ""
    @State private var isLoading = true

    private var filteredApps: [WatchedApp] {
        let alreadyAdded = Set(monitor.watchedApps.map { $0.bundleIdentifier })
        let available = installedApps.filter { !alreadyAdded.contains($0.bundleIdentifier) }

        if searchText.isEmpty {
            return available
        }

        return available.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(settings.text(.selectApplication))
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(settings.text(.done)) { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .padding(16)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(settings.text(.searchPlaceholder), text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Divider()

            if isLoading {
                ProgressView(settings.text(.loadingApplications))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredApps) { app in
                    AppPickerRow(app: app) {
                        var newApp = app
                        newApp.isEnabled = true
                        monitor.watchedApps.append(newApp)
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
        .onAppear {
            loadApps()
        }
    }

    private func loadApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            let apps = monitor.getInstalledApps()
            DispatchQueue.main.async {
                installedApps = apps
                isLoading = false
            }
        }
    }
}

private struct AppPickerRow: View {
    @EnvironmentObject var settings: AppSettings

    let app: WatchedApp
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if let icon = AppIconProvider.icon(for: app.bundleIdentifier) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "app.fill")
                    .frame(width: 24, height: 24)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13))
                Text(app.bundleIdentifier)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(settings.text(.add), action: onAdd)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.vertical, 2)
    }
}
