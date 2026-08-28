import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var settings: AppSettings

    let goBack: () -> Void

    var body: some View {
        HStack {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Text(settings.text(.settingsTitle))
                .font(.system(size: 14, weight: .semibold))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
