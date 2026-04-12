import SwiftUI

// MARK: - Brand Colors

private extension Color {
    static let brandRed    = Color(red: 0.890, green: 0.416, blue: 0.416) // #E36A6A
    static let brandBg     = Color(red: 1.000, green: 0.984, blue: 0.945) // #FFFBF1
    static let brandCard   = Color(red: 1.000, green: 0.949, blue: 0.816) // #FFF2D0
}

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pageCount = 6

    var body: some View {
        ZStack(alignment: .top) {
            Color.brandBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button row
                HStack {
                    Spacer()
                    if currentPage < pageCount - 1 {
                        Button("略過") { finish() }
                            .foregroundStyle(Color.brandRed)
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                }
                .frame(height: 44)

                // Pages
                TabView(selection: $currentPage) {
                    WelcomePage().tag(0)

                    StepPairPage(
                        title: "開始分享",
                        subtitle: "在 Instagram Reel 點分享鍵，再點「分享到」",
                        leftImage: "step1", leftLabel: "① 點分享鍵",
                        rightImage: "step2", rightLabel: "② 點「分享到」"
                    ).tag(1)

                    StepPairPage(
                        title: "選擇 Pindrop",
                        subtitle: "從 App 清單選 Pindrop，再點「地圖」確認位置",
                        leftImage: "step3", leftLabel: "③ 點 Pindrop",
                        rightImage: "step4", rightLabel: "④ 點「地圖」"
                    ).tag(2)

                    ResultPage().tag(3)

                    SetupPage().tag(4)

                    CTAPage(onStart: finish).tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pageCount, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? Color.brandRed : Color.brandRed.opacity(0.25))
                            .frame(width: i == currentPage ? 8 : 6, height: i == currentPage ? 8 : 6)
                            .animation(.spring(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.vertical, 20)
            }
        }
    }

    private func finish() {
        hasSeenOnboarding = true
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

            Text("Pindrop")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Color.brandRed)

            Text("把 Instagram 美食，釘進你的 Google Map")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Page 2 & 3: Step Pair

private struct StepPairPage: View {
    let title: String
    let subtitle: String
    let leftImage: String
    let leftLabel: String
    let rightImage: String
    let rightLabel: String

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2).bold()
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 8)

            HStack(spacing: 12) {
                StepCard(imageName: leftImage, label: leftLabel)
                StepCard(imageName: rightImage, label: rightLabel)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

private struct StepCard: View {
    let imageName: String
    let label: String

    var body: some View {
        VStack(spacing: 10) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.brandCard, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Page 4: Result

private struct ResultPage: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("找到了！")
                    .font(.title).bold()
                    .foregroundStyle(Color.brandRed)
                Text("餐廳地址直接顯示在 Google Map 上")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 8)

            Image("step5")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

            Spacer()
        }
    }
}

// MARK: - Page 5: Setup

private struct SetupPage: View {
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("第一次用？先做這步")
                    .font(.title2).bold()
                Text("把 Pindrop 加到分享選單的喜好項目，之後更快找到")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 8)

            HStack(spacing: 12) {
                StepCard(imageName: "setup1", label: "① 點右下角「更多」")
                StepCard(imageName: "setup2", label: "② 點 Pindrop 旁的「+」")
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

// MARK: - Page 6: CTA

private struct CTAPage: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("準備好了！")
                .font(.system(size: 36, weight: .bold))

            Text("去找你想吃的美食吧")
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: onStart) {
                Text("開始使用 Pindrop")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.brandRed, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
    }
}
