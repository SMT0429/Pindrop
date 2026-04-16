import SwiftUI

struct ShareRootView: View {
    @ObservedObject var viewModel: ShareViewModel
    /// 呼叫端：依 `app` 實際 open URL（Share Extension 走 responder chain）
    let onOpenMaps: (Place, MapsApp) -> Void
    let onComplete: () -> Void
    let onCancel: () -> Void

    /// Picker 當前目標；非 nil 時顯示 confirmationDialog
    @State private var pickerPlace: Place?

    var body: some View {
        let screenH = UIScreen.main.bounds.height
        let panelH: CGFloat = {
            switch viewModel.state {
            case .loading, .error, .confirmation:
                return (screenH / 3).rounded()
            case .selection(let places):
                let computed: CGFloat = 56 + 16 + CGFloat(places.count) * 60 + 90
                return min(computed, screenH * 0.8).rounded()
            }
        }()

        ZStack(alignment: .bottom) {
            // 半透明遮罩（點擊取消）
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            // Bottom panel
            VStack(spacing: 0) {
                // Grabber
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                Group {
                    switch viewModel.state {
                    case .loading:
                        LoadingView()

                    case .confirmation(let place):
                        ConfirmationView(
                            place: place,
                            onOpenMaps: {
                                viewModel.saveHistory(place)
                                handleOpenRequest(place)
                            },
                            onSaveToList: { list in
                                viewModel.saveToList(place, list: list)
                            },
                            onSaveToNewList: { name in
                                viewModel.saveToNewList(place, name: name)
                            },
                            onCancel: onCancel
                        )

                    case .selection(let places):
                        SelectionListView(
                            places: places,
                            onOpenMaps: { place in handleOpenRequest(place) },
                            onSaveToList: { selectedPlaces, list in
                                selectedPlaces.forEach { viewModel.saveToList($0, list: list) }
                            },
                            onSaveToNewList: { selectedPlaces, name in
                                viewModel.saveAllToNewList(selectedPlaces, name: name)
                            },
                            onCancel: onCancel
                        )
                        .onAppear {
                            places.forEach { viewModel.saveHistory($0) }
                        }

                    case .error(let message):
                        ErrorView(message: message, onCancel: onCancel)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: panelH)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .modelContainer(viewModel.modelContainer)
        .confirmationDialog(
            String(localized: "選擇地圖 App"),
            isPresented: Binding(
                get: { pickerPlace != nil },
                set: { if !$0 { pickerPlace = nil } }
            ),
            titleVisibility: .visible,
            presenting: pickerPlace
        ) { place in
            Button(MapsApp.apple.displayName) {
                onOpenMaps(place, .apple)
            }
            Button(MapsApp.google.displayName) {
                onOpenMaps(place, .google)
            }
            Button(String(localized: "取消"), role: .cancel) {
                pickerPlace = nil
            }
        } message: { place in
            Text(place.name)
        }
    }

    /// 依用戶偏好：直接開或顯示 picker。
    private func handleOpenRequest(_ place: Place) {
        if let app = MapsPreferenceStore.resolvedApp {
            onOpenMaps(place, app)
        } else {
            pickerPlace = place
        }
    }
}
