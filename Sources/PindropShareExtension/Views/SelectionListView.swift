import SwiftUI

struct SelectionListView: View {
    let places: [Place]
    let onOpenMaps: (Place) -> Void
    let onSaveToList: ([Place], RestaurantList) -> Void
    let onSaveToNewList: ([Place], String) -> Void
    let onCancel: () -> Void

    @State private var selected: Set<String> = []
    @State private var showListPicker = false
    @State private var savedToList = false

    private var selectedPlaces: [Place] {
        places.filter { selected.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("取消", action: onCancel)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("選擇餐廳")
                    .font(.headline)
                Spacer()
                Text("取消").opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(places) { place in
                        PlaceRow(
                            place: place,
                            isSelected: selected.contains(place.id),
                            onToggle: {
                                if selected.contains(place.id) {
                                    selected.remove(place.id)
                                } else {
                                    selected.insert(place.id)
                                }
                            },
                            onOpenMaps: { onOpenMaps(place) }
                        )

                        if place.id != places.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // Bottom: 儲存至清單
            Divider()

            VStack(spacing: 8) {
                if !selected.isEmpty {
                    Text("已選 \(selected.count) 間餐廳")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button { if !savedToList && !selected.isEmpty { showListPicker = true } } label: {
                    Label(savedToList ? "已儲存" : "儲存至清單",
                          systemImage: savedToList ? "checkmark" : "bookmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    (selected.isEmpty || savedToList) ? Color(.systemGray4) : .red,
                                    lineWidth: 1.5
                                )
                        )
                        .foregroundStyle((selected.isEmpty || savedToList) ? Color(.systemGray2) : .red)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $showListPicker) {
            ListPickerView(
                onSave: { list in
                    showListPicker = false
                    onSaveToList(selectedPlaces, list)
                    savedToList = true
                },
                onSaveNew: { name in
                    showListPicker = false
                    onSaveToNewList(selectedPlaces, name)
                    savedToList = true
                },
                onCancel: { showListPicker = false }
            )
            .presentationDetents([.medium, .large])
        }
    }
}

private struct PlaceRow: View {
    let place: Place
    let isSelected: Bool
    let onToggle: () -> Void
    let onOpenMaps: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.red : Color(.systemGray4), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 24))
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(width: 36)

            // Name + address
            VStack(alignment: .leading, spacing: 3) {
                Text(place.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                if !place.address.isEmpty {
                    Text(place.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer()

            // 在地圖上看
            Button(action: onOpenMaps) {
                Label("地圖", systemImage: "map.fill")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
