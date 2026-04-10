import SwiftUI

struct ErrorView: View {
    let message: String
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("關閉", action: onCancel)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.magnifyingglass")
                    .font(.system(size: 52))
                    .foregroundStyle(.secondary)
                    .padding(.top, 32)

                Text(message)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("請自行在 Google Maps 搜尋餐廳名稱")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}
