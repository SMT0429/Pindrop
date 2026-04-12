import SwiftUI

struct ShareRootView: View {
    @ObservedObject var viewModel: ShareViewModel
    let onOpenMaps: (Place) -> Void
    let onComplete: () -> Void
    let onCancel: () -> Void

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
                                onOpenMaps(place)
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
                            onOpenMaps: { place in onOpenMaps(place) },
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
    }
}
