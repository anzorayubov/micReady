import SwiftUI

struct FooterView: View {
    @EnvironmentObject var settings: AppSettings
    @Binding var showAppPicker: Bool

    var body: some View {
        HStack {
            Button(action: { showAppPicker = true }) {
                Label(settings.text(.addApplication), systemImage: "plus")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
