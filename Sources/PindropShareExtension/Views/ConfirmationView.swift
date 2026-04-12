import SwiftUI

struct ConfirmationView: View {
    let place: Place
    let onOpenMaps: () -> Void
    let onSaveToList: (RestaurantList) -> Void
    let onSaveToNewList: (String) -> Void
    let onCancel: () -> Void

    @State private var showListPicker = false
    @State private var savedToList = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("取消", action: onCancel)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("找到餐廳")
                    .font(.headline)
                Spacer()
                Text("取消").opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            HStack(spacing: 12) {
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

                Button(action: onOpenMaps) {
                    Label("地圖", systemImage: "map.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Spacer()

            // Bottom
            Divider()

            VStack(spacing: 8) {
                Button { if !savedToList { showListPicker = true } } label: {
                    Label(savedToList ? "已儲存" : "儲存至清單",
                          systemImage: savedToList ? "checkmark" : "bookmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(savedToList ? Color(.systemGray4) : .red, lineWidth: 1.5)
                        )
                        .foregroundStyle(savedToList ? Color(.systemGray2) : .red)
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
                    onSaveToList(list)
                    savedToList = true
                },
                onSaveNew: { name in
                    showListPicker = false
                    onSaveToNewList(name)
                    savedToList = true
                },
                onCancel: { showListPicker = false }
            )
            .presentationDetents([.medium, .large])
        }
    }
}
