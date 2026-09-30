import PhotosUI
import SwiftData
import SwiftUI

struct ToyEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Toy.name) private var toys: [Toy]

    @State private var name = ""
    @State private var series = SeedData.seriesNames[0]
    @State private var box: Double = 1
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var saving = false

    private var nameError: String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "Give the figure a name." }
        if toys.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return "\(trimmed) is already in your storage boxes."
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            ScreenScaffold {
                ScreenHeader(title: "New figure", subtitle: "It joins the draw for every shelf that takes its series.")

                SectionCard(title: "Photo") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        if let photoData, let image = UIImage(data: photoData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 180)
                                .clipShape(RoundedRectangle(cornerRadius: AppMetrics.controlRadius))
                        } else {
                            Label("Pick a photo of the figure", systemImage: "photo.badge.plus")
                                .frame(maxWidth: .infinity, minHeight: 88)
                        }
                    }
                }

                SectionCard(title: "Figure") {
                    TextField("Name, e.g. Moss Golem", text: $name)
                        .textInputAutocapitalization(.words)
                        .padding(.vertical, AppMetrics.inputVerticalPadding)
                    if !name.isEmpty, let nameError {
                        InlineError(message: nameError)
                    }
                    SegmentedPicker(
                        title: "Series",
                        options: SeedData.seriesNames.map { SegmentOption($0) },
                        selection: $series
                    )
                    Stepper("Storage box \(Int(box))", value: $box, in: 1...60)
                }

                ActionButton(title: "Save figure", emphasis: .primary, isEnabled: nameError == nil, isLoading: saving) {
                    save()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: photoItem) { _, item in
                Task { photoData = try? await item?.loadTransferable(type: Data.self) }
            }
        }
    }

    private func save() {
        saving = true
        let toy = Toy(
            name: name.trimmingCharacters(in: .whitespaces),
            series: series,
            boxNumber: Int(box),
            hue: Double(abs(name.hashValue % 100)) / 100,
            photoData: photoData
        )
        context.insert(toy)
        try? context.save()
        saving = false
        dismiss()
    }
}

#Preview {
    ToyEditorSheet()
        .previewStore()
}
