import SwiftUI

struct CTAButton: View {
    enum Emphasis {
        case primary
        case secondary
    }

    let title: String
    var systemImage: String?
    var emphasis: Emphasis = .primary
    var hint: String?
    var isEnabled = true
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var feedbackTrigger = 0
    @ScaledMetric(relativeTo: .headline) private var verticalPadding = 14
    @ScaledMetric(relativeTo: .headline) private var labelSpacing = 8

    var body: some View {
        Button(action: performAction) {
            label
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .sensoryFeedback(.impact(weight: .medium), trigger: feedbackTrigger)
        .accessibilityLabel(title)
        .accessibilityHint(hint ?? "")
        .transaction { transaction in
            if reduceMotion {
                transaction.animation = nil
            }
        }
    }

    private var label: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: labelSpacing) {
                labelContent
            }
            VStack(spacing: AppMetrics.tightSpacing) {
                labelContent
            }
        }
        .font(.headline)
        .foregroundStyle(emphasis == .primary ? AppTheme.bgBase : AppTheme.textPrimary)
        .multilineTextAlignment(.center)
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, AppMetrics.cardPadding)
        .background(
            emphasis == .primary ? AppTheme.accent : AppTheme.bgElevated,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay {
            if emphasis == .secondary {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.hairline, lineWidth: AppMetrics.hairlineWidth)
            }
        }
    }

    @ViewBuilder
    private var labelContent: some View {
        if let systemImage {
            Image(systemName: systemImage)
                .accessibilityHidden(true)
        }

        Text(title)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func performAction() {
        feedbackTrigger += 1
        action()
    }
}

#Preview {
    ScreenScaffold {
        CTAButton(title: "Save to project", systemImage: "tray.and.arrow.down") {}
        CTAButton(title: "Start over", emphasis: .secondary) {}
        CTAButton(title: "Export", isEnabled: false) {}
    }
}
