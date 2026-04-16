import SwiftUI

struct HowToUseView: View {
    @AppStorage(MapsPreferenceStore.key) private var mapsPreferenceRaw: String = MapsPreference.ask.rawValue

    private var mapsPreferenceBinding: Binding<MapsPreference> {
        Binding(
            get: { MapsPreference(rawValue: mapsPreferenceRaw) ?? .ask },
            set: { mapsPreferenceRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    headerSection
                    stepsSection
                    mapsPreferenceSection
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

            Text("從 Instagram 一鍵跳轉地圖")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            Text("看到喜歡的餐廳短片，分享給 Pindrop，\n立刻在 Apple 地圖或 Google 地圖找到它。")
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
                title: "選擇地圖 App 開啟",
                description: "選 Apple 地圖或 Google 地圖，或儲存至清單"
            )
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var mapsPreferenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("預設地圖 App")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(MapsPreference.allCases) { option in
                    Button {
                        mapsPreferenceBinding.wrappedValue = option
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: icon(for: option))
                                .font(.title3)
                                .foregroundStyle(.red)
                                .frame(width: 28)

                            Text(option.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.primary)

                            Spacer()

                            if mapsPreferenceBinding.wrappedValue == option {
                                Image(systemName: "checkmark")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if option != MapsPreference.allCases.last {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

            Text("每次詢問時，你可以隨時改變選擇。")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 4)
        }
    }

    private func icon(for option: MapsPreference) -> String {
        switch option {
        case .ask:    return "questionmark.circle"
        case .apple:  return "map"
        case .google: return "map.fill"
        }
    }

    private var requirementNote: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "map.circle.fill")
                    .foregroundStyle(.red)
                    .font(.title3)

                Text("Apple 地圖為內建 App，無需安裝；Google 地圖需另外安裝。")
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
