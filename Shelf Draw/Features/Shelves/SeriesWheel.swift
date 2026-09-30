import SwiftUI

/// Series segments sized by draw priority. The larger slice comes up more often in wheel mode.
struct SeriesWheel: View {
    struct Segment: Identifiable, Equatable {
        var name: String
        var weight: Double
        var hue: Double
        var id: String { name }
    }

    var segments: [Segment]

    var body: some View {
        HStack(spacing: AppMetrics.sectionSpacing) {
            Canvas { context, size in
                let radius = min(size.width, size.height) / 2 - 4
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let total = max(segments.reduce(0) { $0 + $1.weight }, 0.001)
                var start = Angle.degrees(-90)
                for segment in segments {
                    let sweep = Angle.degrees(360 * segment.weight / total)
                    var slice = Path()
                    slice.move(to: center)
                    slice.addArc(center: center, radius: radius, startAngle: start, endAngle: start + sweep, clockwise: false)
                    slice.closeSubpath()
                    context.fill(slice, with: .color(Color(hue: segment.hue, saturation: 0.45, brightness: 0.85)))
                    context.stroke(slice, with: .color(AppTheme.bgBase), lineWidth: 2)
                    start += sweep
                }
                let hub = CGRect(x: center.x - 14, y: center.y - 14, width: 28, height: 28)
                context.fill(Path(ellipseIn: hub), with: .color(AppTheme.bgElevated))
                var pointer = Path()
                pointer.move(to: CGPoint(x: center.x, y: center.y - radius + 16))
                pointer.addLine(to: CGPoint(x: center.x - 7, y: center.y - radius - 4))
                pointer.addLine(to: CGPoint(x: center.x + 7, y: center.y - radius - 4))
                pointer.closeSubpath()
                context.fill(pointer, with: .color(AppTheme.textPrimary))
            }
            .aspectRatio(1, contentMode: .fit)

            VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
                ForEach(segments) { segment in
                    HStack(spacing: AppMetrics.tightSpacing) {
                        Circle()
                            .fill(Color(hue: segment.hue, saturation: 0.45, brightness: 0.85))
                            .frame(width: 10, height: 10)
                        Text(segment.name)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Series wheel: " + segments.map(\.name).joined(separator: ", "))
    }
}

#Preview {
    SeriesWheel(segments: [
        .init(name: "Kaiju Vinyl", weight: 3, hue: 0.3),
        .init(name: "Forest Folk", weight: 2, hue: 0.1),
        .init(name: "Space Crew", weight: 1, hue: 0.6),
    ])
    .frame(height: 180)
    .padding()
}
