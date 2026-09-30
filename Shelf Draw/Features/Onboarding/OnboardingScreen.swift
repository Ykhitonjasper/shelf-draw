import SwiftUI

struct OnboardingScreen: View {
    var onFinish: (String) -> Void

    @State private var page = 0
    @State private var slot: Int? = 5
    @State private var pickedShelf = 0

    private let sampleFigures: [Int: Color] = [
        0: Color(hue: 0.33, saturation: 0.55, brightness: 0.82),
        1: Color(hue: 0.92, saturation: 0.55, brightness: 0.82),
        2: Color(hue: 0.58, saturation: 0.55, brightness: 0.82),
        4: Color(hue: 0.28, saturation: 0.55, brightness: 0.82),
    ]

    private var shelfNames: [String] {
        let names = SeedData.shelves.map(\.name)
        return Array(names[pickedShelf...]) + Array(names[..<pickedShelf])
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pageCount = 3
    private let readableWidth: CGFloat = 680

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                GeometryReader { proxy in
                    ScrollView {
                        Group {
                            switch page {
                            case 0: shelfPage
                            case 1: stackPage
                            default: devicePage
                            }
                        }
                        .id(page)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .padding(AppMetrics.screenPadding)
                        .frame(maxWidth: readableWidth)
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }

                VStack(spacing: AppMetrics.sectionSpacing) {
                    HStack(spacing: 8) {
                        ForEach(0..<pageCount, id: \.self) { index in
                            Capsule()
                                .fill(index == page ? AppTheme.accent : AppTheme.hairline)
                                .frame(width: index == page ? 22 : 8, height: 8)
                        }
                    }
                    .accessibilityElement()
                    .accessibilityLabel("Page \(page + 1) of \(pageCount)")

                    CTAButton(title: page < pageCount - 1 ? "Next" : "Start", systemImage: page < pageCount - 1 ? "arrow.right" : "checkmark", emphasis: .primary) {
                        if page < pageCount - 1 {
                            withAnimation(reduceMotion ? nil : .snappy) { page += 1 }
                        } else {
                            onFinish(SeedData.shelves[pickedShelf].name)
                        }
                    }
                }
                .padding(.horizontal, AppMetrics.screenPadding)
                .padding(.bottom, AppMetrics.screenPadding)
                .frame(maxWidth: readableWidth)
            }
        }
    }

    private var shelfPage: some View {
        VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
            ScreenHeader(title: "Your shelf, one figure at a time", subtitle: "Drag across the boards to pick the empty slot for the next figure.")
            GeometryReader { proxy in
                ShelfMark(columns: 4, rows: 2, figures: sampleFigures, target: slot, ghost: Color(hue: 0.08, saturation: 0.55, brightness: 0.82))
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                        slot = ShelfMark.slot(at: value.location, in: proxy.size, columns: 4, rows: 2)
                    })
            }
            .frame(height: 220)
            .cardSurface()
            StatusBanner(message: "A decision tool for the shelf: it picks which boxed figure goes up next. No prizes, no purchases.", tone: .note)
        }
    }

    private var stackPage: some View {
        VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
            ScreenHeader(title: "Pick the shelf you rotate first", subtitle: "Tap the stack until your shelf is on top. Twelve sample shelves are ready.")
            TicketStack(names: shelfNames, selected: 0) { _ in
                pickedShelf = (pickedShelf + 1) % SeedData.shelves.count
            }
            .padding(.bottom, AppMetrics.tightSpacing)
            TagChip(title: "First draw goes to \(SeedData.shelves[pickedShelf].name)", systemImage: "books.vertical")
        }
    }

    private var devicePage: some View {
        VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
            ScreenHeader(title: "Your collection stays on this phone", subtitle: "Figures, photos, and placements are saved on this device only. No account.")
            SectionCard(title: "What comes with it") {
                DetailRow(label: "Sample figures", value: "\(SeedData.toys.count) in 12 boxes")
                DetailRow(label: "Shelves", value: "\(SeedData.shelves.count)")
                DetailRow(label: "Past placements", value: "\(SeedData.placements.count)")
            }
        }
    }
}

#Preview {
    OnboardingScreen(onFinish: { _ in })
}
