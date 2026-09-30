import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var feedbackTrigger = 0
    @ScaledMetric(relativeTo: .subheadline) private var horizontalPadding = AppMetrics.contentSpacing
    @ScaledMetric(relativeTo: .subheadline) private var verticalPadding = 8

    var body: some View {
        Button(action: performAction) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? AppTheme.bgBase : AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .background(isSelected ? AppTheme.accent : AppTheme.bgElevated, in: Capsule())
                .overlay {
                    Capsule().stroke(AppTheme.hairline, lineWidth: AppMetrics.hairlineWidth)
                }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: feedbackTrigger)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .transaction { transaction in
            if reduceMotion {
                transaction.animation = nil
            }
        }
    }

    private func performAction() {
        feedbackTrigger += 1
        action()
    }
}

struct TagChip: View {
    let title: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(AppTheme.textMono)
        .pillSurface()
        .accessibilityElement(children: .combine)
    }
}

struct ChipRow<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                content
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    ScreenScaffold {
        ChipRow {
            FilterChip(title: "All", isSelected: true) {}
            FilterChip(title: "Cold", isSelected: false) {}
            FilterChip(title: "Hot", isSelected: false) {}
        }
        TagChip(title: "Coarse grind", systemImage: "circle.grid.2x2")
    }
}
