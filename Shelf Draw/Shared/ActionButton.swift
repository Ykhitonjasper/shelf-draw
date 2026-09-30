import SwiftUI

struct ActionButton: View {
    enum Emphasis {
        case primary
        case secondary
        case destructive
    }

    let title: String
    var systemImage: String?
    var emphasis: Emphasis = .primary
    var hint: String?
    var isEnabled = true
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                label
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(foreground)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(title)
        .accessibilityHint(hint ?? "")
        .accessibilityValue(isLoading ? "Working" : "")
    }

    private var foreground: Color {
        switch emphasis {
        case .primary, .destructive:
            return AppTheme.bgBase
        case .secondary:
            return AppTheme.textPrimary
        }
    }

    private var fill: Color {
        switch emphasis {
        case .primary:
            return AppTheme.accent
        case .secondary:
            return AppTheme.bgElevated
        case .destructive:
            return AppTheme.danger
        }
    }

    private var label: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .accessibilityHidden(true)
            }
            Text(title)
        }
        .font(.headline)
        .foregroundStyle(foreground)
        .padding(.vertical, 14)
        .padding(.horizontal, AppMetrics.cardPadding)
        .background(fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            if emphasis == .secondary {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.hairline, lineWidth: AppMetrics.hairlineWidth)
            }
        }
    }
}

#Preview {
    ScreenScaffold {
        ActionButton(title: "Save the board", systemImage: "tray.and.arrow.down") {}
        ActionButton(title: "Saving", isLoading: true) {}
        ActionButton(title: "Start over", emphasis: .secondary) {}
        ActionButton(title: "Clear the log", emphasis: .destructive) {}
    }
}
