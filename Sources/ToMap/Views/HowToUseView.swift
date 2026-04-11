import SwiftUI

struct HowToUseView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    headerSection
                    stepsSection
                    requirementNote
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("使用說明")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "map.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)

            Text("從 Instagram 一鍵跳轉 Google Maps")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            Text("看到喜歡的餐廳短片，分享給 Pindrop，\n立刻在 Google Maps 找到它。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("使用方法")
                .font(.headline)
                .foregroundStyle(.secondary)

            StepRow(
                number: 1,
                icon: "play.rectangle.fill",
                iconColor: .purple,
                title: "在 Instagram 找到餐廳短片",
                description: "看到想去的餐廳影片"
            )

            StepRow(
                number: 2,
                icon: "square.and.arrow.up",
                iconColor: .blue,
                title: "點擊「分享」",
                description: "在分享選單中選擇「Pindrop」"
            )

            StepRow(
                number: 3,
                icon: "mappin.circle.fill",
                iconColor: .red,
                title: "選擇開啟方式",
                description: "在 Google Maps 開啟，或儲存至清單"
            )
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var requirementNote: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)

                Text("請先確認已安裝 **Google Maps** App")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            HStack(spacing: 12) {
                Image(systemName: "iphone")
                    .foregroundStyle(.secondary)
                    .font(.title3)

                Text("需要 **iOS 17.0** 或更新版本")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct StepRow: View {
    let number: Int
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
