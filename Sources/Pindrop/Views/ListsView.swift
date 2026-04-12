import SwiftUI
import SwiftData

struct ListsView: View {
    @Query(sort: \RestaurantList.createdAt) private var lists: [RestaurantList]
    @Environment(\.modelContext) private var context
    @State private var showCreateSheet = false
    @State private var newListName = ""

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(lists) { list in
                            NavigationLink {
                                ListDetailView(list: list)
                            } label: {
                                ListRowView(list: list)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { context.delete(lists[$0]) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("清單")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newListName = ""
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateListSheet(onCreate: { name in
                    let list = RestaurantList(name: name)
                    context.insert(list)
                    showCreateSheet = false
                }, onCancel: {
                    showCreateSheet = false
                })
                .presentationDetents([.height(200)])
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("還沒有清單")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("點右上角 + 建立清單，\n或從分享選單選「儲存至清單」。")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Button {
                newListName = ""
                showCreateSheet = true
            } label: {
                Label("建立清單", systemImage: "plus")
                    .font(.subheadline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.red, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ListRowView: View {
    let list: RestaurantList

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundStyle(.red)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(list.name)
                    .font(.headline)
                Text("\(list.items.count) 間餐廳")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CreateListSheet: View {
    let onCreate: (String) -> Void
    let onCancel: () -> Void
    @State private var name = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("建立新清單")
                .font(.headline)
                .padding(.top, 20)

            TextField("清單名稱", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 24)
                .submitLabel(.done)
                .onSubmit { commit() }

            HStack(spacing: 16) {
                Button("取消", action: onCancel)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.secondary.opacity(0.4)))

                Button("建立", action: commit)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.red, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)
        }
    }

    private func commit() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onCreate(trimmed)
    }
}
