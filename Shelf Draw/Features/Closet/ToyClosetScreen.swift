import SwiftData
import SwiftUI

struct ToyClosetScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Toy.boxNumber) private var toys: [Toy]

    @State private var search = ""
    @State private var showAdd = false
    @State private var opened: Toy?
    @State private var pendingDelete: Toy?

    private var visible: [Toy] {
        guard !search.isEmpty else { return toys }
        return toys.filter {
            $0.name.localizedCaseInsensitiveContains(search)
                || $0.series.localizedCaseInsensitiveContains(search)
                || "box \($0.boxNumber)".contains(search.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            ScreenScaffold {
                ScreenHeader(
                    title: "\(toys.count) figures in \(Set(toys.map(\.boxNumber)).count) boxes",
                    subtitle: "The storage closet every shelf draws from"
                )

                if visible.isEmpty {
                    EmptyStateCard(
                        title: search.isEmpty ? "The boxes are empty" : "No figure matches \(search)",
                        message: "Add a figure with a photo so the draw can put it on a shelf.",
                        systemImage: "shippingbox",
                        actionTitle: "Add figure",
                        action: { showAdd = true }
                    )
                } else {
                    ForEach(visible) { toy in
                        SwipeRow(
                            title: toy.name,
                            subtitle: "Box \(toy.boxNumber) · \(toy.series) · \(toy.lastShown == nil ? "never on a shelf" : "\(toy.daysBoxed) days boxed")",
                            systemImage: toy.photoData == nil ? "figure.stand" : "photo",
                            onTap: { opened = toy }
                        ) {
                            Button(role: .destructive) {
                                pendingDelete = toy
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }

                CTAButton(title: "Add figure", systemImage: "plus", emphasis: .primary) {
                    showAdd = true
                }
            }
            .navigationTitle("Storage boxes")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Name, series, or box")
            .navigationDestination(item: $opened) { toy in
                ToyDetailScreen(toy: toy)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                ToyEditorSheet()
            }
            .confirmationDialog(
                "Delete \(pendingDelete?.name ?? "figure")?",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button(role: .destructive) {
                    if let pendingDelete {
                        context.delete(pendingDelete)
                        try? context.save()
                    }
                    pendingDelete = nil
                } label: {
                    Text("Delete figure")
                }
            } message: {
                Text("Its past placements stay in the Log.")
            }
        }
    }
}

#Preview {
    ToyClosetScreen()
        .previewStore()
}
