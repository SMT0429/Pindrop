import SwiftUI
import SwiftData

struct ListPickerView: View {
    let onSave: (RestaurantList) -> Void
    let onSaveNew: (String) -> Void
    let onCancel: () -> Void

    @Query(sort: \RestaurantList.createdAt) private var lists: [RestaurantList]
    @State private var showNewListField = false
    @State private var newListName = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("取消", action: onCancel)
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
                    // 建立新清單
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

                        Divider().padding(.leading, 56)
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

                        if !lists.isEmpty {
                            Divider().padding(.leading, 56)
                        }
                    }

                    // 現有清單
                    ForEach(lists) { list in
                        Button {
                            onSave(list)
                        } label: {
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

    private func commitNewList() {
        let trimmed = newListName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onSaveNew(trimmed)
    }
}
