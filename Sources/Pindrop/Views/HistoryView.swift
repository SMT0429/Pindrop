import SwiftUI
import SwiftData
import UIKit

struct HistoryView: View {
    @Query(sort: \HistoryEntry.openedAt, order: .reverse) private var entries: [HistoryEntry]
    @Environment(\.modelContext) private var context

    @State private var pickerTarget: MapsTarget?

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(entries) { entry in
                            HistoryRowView(entry: entry, pickerTarget: $pickerTarget)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { context.delete(entries[$0]) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("過往記錄")
            .navigationBarTitleDisplayMode(.large)
        }
        .mapsPicker(target: $pickerTarget) { app, target in
            MapsLauncher.openImmediately(target, with: app)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("還沒有記錄")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("從 Instagram 分享餐廳短片後，\n點「地圖」會自動記錄在這裡。")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct HistoryRowView: View {
    let entry: HistoryEntry
    @Binding var pickerTarget: MapsTarget?
    @State private var showSaveSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.name)
                .font(.headline)

            if !entry.address.isEmpty {
                Text(entry.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(entry.openedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button { showSaveSheet = true } label: {
                    Label("儲存", systemImage: "bookmark")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button {
                    MapsLauncher.requestOpen(
                        MapsTarget(placeId: entry.placeId, name: entry.name, address: entry.address),
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
        .sheet(isPresented: $showSaveSheet) {
            SaveToListSheet(
                placeId: entry.placeId,
                name: entry.name,
                address: entry.address,
                onDismiss: { showSaveSheet = false }
            )
            .presentationDetents([.medium, .large])
        }
    }
}

private struct SaveToListSheet: View {
    let placeId: String
    let name: String
    let address: String
    let onDismiss: () -> Void

    @Query(sort: \RestaurantList.createdAt) private var lists: [RestaurantList]
    @Environment(\.modelContext) private var context
    @State private var showNewListField = false
    @State private var newListName = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("取消", action: onDismiss)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("儲存至清單")
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
                    if showNewListField {
                        HStack(spacing: 12) {
                            Image(systemName: "folder.badge.plus")
                                .font(.title2)
                                .foregroundStyle(.red)
                                .frame(width: 36)

                            TextField("清單名稱", text: $newListName)
                                .font(.subheadline)
                                .submitLabel(.done)
                                .onSubmit { commitNewList() }

                            if !newListName.isEmpty {
                                Button("確定", action: commitNewList)
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        if !lists.isEmpty { Divider().padding(.leading, 56) }
                    } else {
                        Button {
                            showNewListField = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(.red)
                                    .frame(width: 36)
                                Text("建立新清單")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if !lists.isEmpty { Divider().padding(.leading, 56) }
                    }

                    ForEach(lists) { list in
                        Button { saveToList(list) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "folder")
                                    .font(.title2)
                                    .foregroundStyle(.red)
                                    .frame(width: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(list.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text("\(list.items.count) 間餐廳")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if list.id != lists.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private func saveToList(_ list: RestaurantList) {
        let item = RestaurantItem(placeId: placeId, name: name, address: address)
        item.list = list
        context.insert(item)
        try? context.save()
        onDismiss()
    }

    private func commitNewList() {
        let trimmed = newListName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let list = RestaurantList(name: trimmed)
        context.insert(list)
        let item = RestaurantItem(placeId: placeId, name: name, address: address)
        item.list = list
        context.insert(item)
        try? context.save()
        onDismiss()
    }
}
