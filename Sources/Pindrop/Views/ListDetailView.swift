import SwiftUI
import SwiftData
import UIKit

struct ListDetailView: View {
    @Bindable var list: RestaurantList
    @Environment(\.modelContext) private var context
    @State private var showRenameAlert = false
    @State private var newName = ""
    @State private var pickerTarget: MapsTarget?

    private var sortedItems: [RestaurantItem] {
        list.items.sorted { $0.savedAt > $1.savedAt }
    }

    var body: some View {
        Group {
            if list.items.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(sortedItems) { item in
                        RestaurantItemRowView(item: item, pickerTarget: $pickerTarget)
                    }
                    .onDelete { indexSet in
                        let sorted = sortedItems
                        indexSet.forEach { context.delete(sorted[$0]) }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newName = list.name
                    showRenameAlert = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .alert("重新命名", isPresented: $showRenameAlert) {
            TextField("清單名稱", text: $newName)
            Button("確定") {
                let trimmed = newName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { list.name = trimmed }
            }
            Button("取消", role: .cancel) {}
        }
        .mapsPicker(target: $pickerTarget) { app, target in
            MapsLauncher.openImmediately(target, with: app)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("清單是空的")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("從分享選單點「儲存至清單」\n將餐廳加入這個清單。")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct RestaurantItemRowView: View {
    let item: RestaurantItem
    @Binding var pickerTarget: MapsTarget?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.name)
                .font(.headline)

            if !item.address.isEmpty {
                Text(item.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(item.savedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button {
                    MapsLauncher.requestOpen(
                        MapsTarget(placeId: item.placeId, name: item.name, address: item.address),
                        pickerTarget: $pickerTarget
                    )
                } label: {
                    Label("地圖", systemImage: "map.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(.vertical, 4)
    }
}
