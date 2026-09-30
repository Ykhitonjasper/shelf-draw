import SwiftUI

struct AppBackground: View {
    var body: some View {
        Group {
            switch PackCharacter.surface {
            case "flat":
                AppTheme.bgBase
            case "ruled":
                ruledFill
            default:
                materialFill
            }
        }
        .ignoresSafeArea()
    }

    private var materialFill: some View {
        ZStack {
            AppTheme.bgBase

            LinearGradient(
                colors: [AppTheme.bgElevated.opacity(0.32), .clear],
                startPoint: .top,
                endPoint: .center
            )

            RadialGradient(
                colors: [AppTheme.backgroundGlow.opacity(0.32), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
        }
    }

    private var ruledFill: some View {
        ZStack {
            AppTheme.bgBase
            GeometryReader { geo in
                Path { path in
                    var y: CGFloat = 0
                    while y < geo.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        y += 28
                    }
                }
                .stroke(AppTheme.hairline.opacity(0.45), lineWidth: 0.5)
            }
        }
    }
}

#Preview {
    AppBackground()
}
