import SwiftUI

struct TapeLine: Identifiable, Hashable {
    var id: String
    var stamp: String
    var text: String
}

struct ComposerTape: View {
    var lines: [TapeLine]
    @Binding var draft: String
    var sendTitle: String
    var onSend: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isComposerFocused: Bool
    @State private var commitCount = 0

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.contentSpacing) {
            if lines.isEmpty {
                ViewThatFits {
                    ContentUnavailableView(
                        "Tape is empty",
                        systemImage: "text.line.first.and.arrowtriangle.forward",
                        description: Text("Write the first line below.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 220)

                    Label("Tape is empty. Write the first line below.", systemImage: "square.and.pencil")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                }
                .accessibilityLabel("Tape is empty. Write the first line")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
                        ForEach(lines) { line in
                            VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
                                Text(line.stamp)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text(line.text)
                                    .font(.body)
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(line.stamp), \(line.text)")
                        }
                    }
                    .padding(.vertical, AppMetrics.sectionSpacing)
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppMetrics.contentSpacing) {
                    composerField
                    commitButton
                }
                VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
                    composerField
                    commitButton
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, AppMetrics.contentSpacing)

            Text(trimmedDraft.isEmpty ? "Ready for a new line" : "Draft ready to add")
                .font(.caption.weight(.semibold))
                .foregroundStyle(trimmedDraft.isEmpty ? AppTheme.textSecondary : AppTheme.accent)
                .accessibilityLabel(trimmedDraft.isEmpty ? "Composer empty" : "Draft ready")
        }
        .frame(minHeight: 320)
        .sensoryFeedback(.success, trigger: commitCount)
        .animation(reduceMotion ? nil : .easeInOut, value: lines.count)
        .accessibilityAction(named: "Focus composer") {
            isComposerFocused = true
        }
        .accessibilityAction(named: sendTitle) {
            commit()
        }
        .accessibilityLabel("Composer tape")
        .accessibilityValue(trimmedDraft.isEmpty ? "Ready for a new line" : "Draft selected and ready to add")
    }

    private var composerField: some View {
        TextField("Note", text: $draft, axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(1...4)
            .focused($isComposerFocused)
            .submitLabel(.send)
            .onSubmit(commit)
            .accessibilityLabel("New tape line")
    }

    private var commitButton: some View {
        Button(sendTitle, action: commit)
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .disabled(trimmedDraft.isEmpty)
            .accessibilityLabel("\(sendTitle) tape line")
    }

    private func commit() {
        guard !trimmedDraft.isEmpty else { return }
        onSend()
        commitCount += 1
        if !reduceMotion {
            isComposerFocused = true
        }
    }
}

#Preview {
    ComposerTapePreview()
}

private struct ComposerTapePreview: View {
    @State private var draft = ""

    private let lines = [
        TapeLine(id: "1", stamp: "Tue 7:40", text: "Wall held at 4.8 mm."),
        TapeLine(id: "2", stamp: "Tue 8:05", text: "Wet lip measured 92 mm."),
        TapeLine(id: "3", stamp: "Tue 8:24", text: "Added a narrow foot."),
        TapeLine(id: "4", stamp: "Tue 9:10", text: "First trim complete."),
        TapeLine(id: "5", stamp: "Wed 14:30", text: "Surface is leather hard."),
        TapeLine(id: "6", stamp: "Thu 10:15", text: "Clear glaze test applied."),
        TapeLine(id: "7", stamp: "Fri 8:20", text: "Foot waxed before the second coat."),
        TapeLine(id: "8", stamp: "Sat 16:05", text: "Loaded on the middle shelf with a cone pack.")
    ]

    var body: some View {
        ScreenScaffold {
            ComposerTape(
                lines: lines,
                draft: $draft,
                sendTitle: "Add",
                onSend: { draft = "" }
            )
        }
    }
}
