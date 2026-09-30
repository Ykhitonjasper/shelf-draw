import SwiftData
import SwiftUI

struct SettingsScreen: View {
    var onDeleteAll: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage("staleBoost") private var staleBoost = 1.0
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            ScreenScaffold {
                SectionCard(title: "Shelf draw", footnote: "Higher means figures that sat in a box longer come up more often on every shelf.") {
                    Text("Favour long-boxed figures ×\(staleBoost.formatted(.number.precision(.fractionLength(1))))")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Slider(value: $staleBoost, in: 0...2, step: 0.1)
                        .accessibilityLabel("Favour long-boxed figures")
                }

                SectionCard(title: "Legal") {
                    NavigationRow(title: "Privacy Policy", systemImage: "hand.raised") {
                        if let url = Legal.privacy { openURL(url) }
                    }
                    NavigationRow(title: "Terms of Use", systemImage: "doc.text") {
                        if let url = Legal.terms { openURL(url) }
                    }
                }

                SectionCard(title: "Data", footnote: "Figures, shelves, and placements live on this phone only.") {
                    DetailRow(label: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    ActionButton(title: "Delete All Data", systemImage: "trash", emphasis: .destructive) {
                        confirmDelete = true
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete all figures, shelves, and placements?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button(role: .destructive) {
                    dismiss()
                    onDeleteAll()
                } label: {
                    Text("Delete everything")
                }
            } message: {
                Text("This clears the storage boxes and the log, then starts the intro again.")
            }
        }
    }
}

#Preview {
    SettingsScreen(onDeleteAll: {})
}
