import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
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
    }
}
