import SwiftUI

struct DetailScaffold<Geometry: View, Action: View>: View {
    let title: String
    var subtitle: String?
    private let geometry: () -> Geometry
    private let action: () -> Action

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder geometry: @escaping () -> Geometry,
        @ViewBuilder action: @escaping () -> Action
    ) {
        self.title = title
        self.subtitle = subtitle
        self.geometry = geometry
        self.action = action
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
                    ScreenHeader(title: title, subtitle: subtitle)

                    geometry()
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .contain)
                }
                .padding(AppMetrics.screenPadding)
            }
        }
        .safeAreaInset(edge: .bottom) {
            action()
                .padding(.horizontal, AppMetrics.screenPadding)
                .padding(.vertical, AppMetrics.contentSpacing)
                .background(AppTheme.bgBase)
        }
    }
}

#Preview {
    NavigationStack {
        DetailScaffold(
            title: "Batch detail",
            subtitle: "A compact view of the current steep."
        ) {
            RoundedRectangle(cornerRadius: AppMetrics.cardRadius, style: .continuous)
                .fill(AppTheme.bgElevated)
                .frame(height: 220)
                .overlay {
                    Image(systemName: "drop")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                        .accessibilityLabel("Water drop preview")
                }
        } action: {
            CTAButton(
                title: "Save batch",
                systemImage: "tray.and.arrow.down"
            ) {}
        }
    }
}
