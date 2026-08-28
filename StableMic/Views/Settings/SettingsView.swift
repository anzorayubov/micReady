import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var launchAtLoginEnabled = false
    @State private var launchAtLoginError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                Toggle(
                    settings.text(.launchAtLogin),
                    isOn: Binding(
                        get: { launchAtLoginEnabled },
                        set: updateLaunchAtLogin
                    )
                )
                .toggleStyle(.checkbox)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text(settings.text(.languageSectionTitle))
                        .font(.system(size: 12, weight: .semibold))
                    Text(settings.text(.languageSectionDescription))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Picker("", selection: $settings.selectedLanguage) {
                    ForEach(AppSettings.AppLanguage.allCases) { language in
                        Text(settings.languageDisplayName(language))
                            .tag(language)
                    }
                }
                .labelsHidden()
                .pickerStyle(.radioGroup)

                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.text(.currentLanguageLabel))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(settings.resolvedLanguageDescription)
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .padding(16)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear(perform: refreshLaunchAtLoginStatus)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshLaunchAtLoginStatus()
        }
        .alert(
            settings.text(.settingsTitle),
            isPresented: Binding(
                get: { launchAtLoginError != nil },
                set: { isPresented in
                    if !isPresented {
                        launchAtLoginError = nil
                    }
                }
            )
        ) {
            Button(settings.text(.done)) {
                launchAtLoginError = nil
            }
        } message: {
            Text(launchAtLoginError ?? "")
        }
    }

    private func updateLaunchAtLogin(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLoginError = error.localizedDescription
        }

        refreshLaunchAtLoginStatus()
    }

    private func refreshLaunchAtLoginStatus() {
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }
}
