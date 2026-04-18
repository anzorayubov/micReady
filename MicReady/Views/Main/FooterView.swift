import AppKit
import SwiftUI

struct FooterView: View {
    @EnvironmentObject var settings: AppSettings
    @Binding var showAppPicker: Bool

    var body: some View {
        HStack {
            Button(action: { showAppPicker = true }) {
                Label(settings.text(.addApplication), systemImage: "plus")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)

            Spacer()

            Button(action: { NSApp.terminate(nil) }) {
                Text(settings.text(.quit))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
