import SwiftUI

struct StatusBanner: View {
    enum Tone {
        case note
        case warning
        case danger
    }

    let message: String
    var tone: Tone = .note

    var body: some View {
        HStack(alignment: .top, spacing: AppMetrics.contentSpacing) {
            Image(systemName: symbol)
                .foregroundStyle(glyph)
                .accessibilityHidden(true)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppMetrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: AppMetrics.controlRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppMetrics.controlRadius, style: .continuous)
                .stroke(glyph, lineWidth: AppMetrics.hairlineWidth)
        }
        .accessibilityElement(children: .combine)
    }

    private var symbol: String {
        switch tone {
        case .note:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .danger:
            return "xmark.octagon"
        }
    }

    private var glyph: Color {
        switch tone {
        case .note:
            return AppTheme.textSecondary
        case .warning:
            return AppTheme.accent
        case .danger:
            return AppTheme.danger
        }
    }
}

#Preview {
    ScreenScaffold {
        StatusBanner(message: "Saved on this phone.")
        StatusBanner(message: "Check the numbers before you keep this.", tone: .warning)
        StatusBanner(message: "That value is outside the range.", tone: .danger)
    }
}
