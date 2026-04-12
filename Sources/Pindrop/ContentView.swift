import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private var showOnboarding: Binding<Bool> {
        Binding(
            get: { !hasSeenOnboarding },
            set: { if !$0 { hasSeenOnboarding = true } }
        )
    }

    var body: some View {
        TabView {
            HistoryView()
                .tabItem { Label("過往記錄", systemImage: "clock.fill") }

            ListsView()
                .tabItem { Label("清單", systemImage: "bookmark.fill") }

            HowToUseView()
                .tabItem { Label("使用說明", systemImage: "questionmark.circle.fill") }
        }
        .fullScreenCover(isPresented: showOnboarding) {
            OnboardingView()
        }
    }
}
