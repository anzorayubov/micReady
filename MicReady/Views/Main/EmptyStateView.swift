import SwiftUI

struct EmptyStateView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "app.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text(settings.text(.emptyTitle))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text(settings.text(.emptySubtitle))
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
