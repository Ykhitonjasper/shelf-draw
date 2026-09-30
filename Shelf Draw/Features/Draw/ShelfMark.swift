import SwiftUI

/// A wall shelf seen head-on: boards, slot dividers, and a tiger-cub figure in each filled slot.
struct ShelfMark: View {
    var columns: Int
    var rows: Int
    var figures: [Int: Color]
    var target: Int?
    var ghost: Color?

    var body: some View {
        Canvas { context, size in
            let cols = max(columns, 1)
            let rowCount = max(rows, 1)
            let board: CGFloat = 8
            let rowHeight = size.height / CGFloat(rowCount)
            let slotWidth = size.width / CGFloat(cols)

            for row in 0..<rowCount {
                let floorY = rowHeight * CGFloat(row + 1) - board
                let plank = CGRect(x: 0, y: floorY, width: size.width, height: board)
                context.fill(Path(roundedRect: plank, cornerRadius: 3), with: .color(Self.wood))
                context.fill(Path(CGRect(x: 2, y: floorY, width: size.width - 4, height: 2)), with: .color(AppTheme.textPrimary.opacity(0.35)))

                for col in 0..<cols {
                    let index = row * cols + col
                    let cell = CGRect(x: CGFloat(col) * slotWidth, y: rowHeight * CGFloat(row), width: slotWidth, height: rowHeight - board)

                    if col > 0 {
                        var divider = Path()
                        divider.move(to: CGPoint(x: cell.minX, y: cell.minY + 10))
                        divider.addLine(to: CGPoint(x: cell.minX, y: cell.maxY))
                        context.stroke(divider, with: .color(AppTheme.hairline), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                    }

                    if index == target {
                        let glow = cell.insetBy(dx: 4, dy: 6)
                        context.fill(Path(roundedRect: glow, cornerRadius: 10), with: .color(AppTheme.accent.opacity(0.16)))
                        context.stroke(Path(roundedRect: glow, cornerRadius: 10), with: .color(AppTheme.accent), lineWidth: 2)
                    }

                    if let tint = figures[index] {
                        drawFigure(in: cell, tint: tint, alpha: 1, context: &context)
                    } else if index == target, let ghost {
                        drawFigure(in: cell, tint: ghost, alpha: 0.55, context: &context)
                    } else {
                        let dash = StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                        context.stroke(figurePath(in: cell), with: .color(AppTheme.textSecondary.opacity(0.35)), style: dash)
                    }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Shelf with \(figures.count) of \(columns * rows) slots filled")
        .accessibilityValue(target.map { "Target slot \($0 + 1)" } ?? "No target slot")
    }

    private static let wood = Color(red: 0.80, green: 0.46, blue: 0.20)
    private static let fur = Color(red: 0.96, green: 0.56, blue: 0.16)
    private static let stripe = Color(red: 0.11, green: 0.09, blue: 0.08)
    private static let cream = Color(red: 1.0, green: 0.95, blue: 0.86)

    private struct TigerParts {
        var head: CGRect
        var body: CGRect
        var ears: [CGRect]
        var innerEars: [CGRect]
        var tail: Path
        var tailWidth: CGFloat
    }

    private func tigerParts(in cell: CGRect) -> (parts: TigerParts, h: CGFloat, base: CGPoint) {
        let h = min(cell.height * 0.78, cell.width * 1.1)
        let base = CGPoint(x: cell.midX, y: cell.maxY)
        let body = CGRect(x: base.x - h * 0.23, y: base.y - h * 0.52, width: h * 0.46, height: h * 0.52)
        let head = CGRect(x: base.x - h * 0.26, y: base.y - h * 0.9, width: h * 0.52, height: h * 0.44)
        let ears = [-1.0, 1.0].map { side in
            CGRect(x: base.x + side * h * 0.18 - h * 0.09, y: base.y - h * 0.95, width: h * 0.18, height: h * 0.18)
        }
        let innerEars = ears.map { $0.insetBy(dx: h * 0.045, dy: h * 0.045) }
        var tail = Path()
        tail.move(to: CGPoint(x: base.x + h * 0.18, y: base.y - h * 0.1))
        tail.addQuadCurve(to: CGPoint(x: base.x + h * 0.4, y: base.y - h * 0.34),
                          control: CGPoint(x: base.x + h * 0.46, y: base.y - h * 0.06))
        return (TigerParts(head: head, body: body, ears: ears, innerEars: innerEars, tail: tail, tailWidth: h * 0.08), h, base)
    }

    /// Single-outline silhouette so the dashed empty slot has no inner seams.
    private func figurePath(in cell: CGRect) -> Path {
        let (parts, h, _) = tigerParts(in: cell)
        var shape = Path(roundedRect: parts.body, cornerRadius: h * 0.2)
            .union(Path(ellipseIn: parts.head))
            .union(parts.tail.strokedPath(StrokeStyle(lineWidth: parts.tailWidth, lineCap: .round)))
        for ear in parts.ears {
            shape = shape.union(Path(ellipseIn: ear))
        }
        return shape
    }

    private func drawFigure(in cell: CGRect, tint: Color, alpha: Double, context: inout GraphicsContext) {
        let (parts, h, base) = tigerParts(in: cell)
        let stand = CGRect(x: base.x - h * 0.3, y: base.y - 4, width: h * 0.6, height: 4)
        let thin = StrokeStyle(lineWidth: max(h * 0.035, 1.2), lineCap: .round)
        func point(_ dx: CGFloat, _ dy: CGFloat) -> CGPoint { CGPoint(x: base.x + dx * h, y: base.y - dy * h) }
        func line(_ a: CGPoint, _ b: CGPoint) -> Path { var p = Path(); p.move(to: a); p.addLine(to: b); return p }

        var layer = context
        layer.opacity = alpha

        // Tail with a dark tip and a couple of rings.
        layer.stroke(parts.tail, with: .color(Self.fur), style: StrokeStyle(lineWidth: parts.tailWidth, lineCap: .round))
        layer.fill(Path(ellipseIn: CGRect(x: base.x + h * 0.36, y: base.y - h * 0.38, width: h * 0.08, height: h * 0.08)), with: .color(Self.stripe))
        layer.stroke(line(point(0.33, 0.13), point(0.29, 0.18)), with: .color(Self.stripe), style: thin)
        layer.stroke(line(point(0.4, 0.2), point(0.35, 0.23)), with: .color(Self.stripe), style: thin)

        // Body, belly, side stripes, paws.
        layer.fill(Path(roundedRect: parts.body, cornerRadius: h * 0.2), with: .color(Self.fur))
        layer.fill(Path(ellipseIn: CGRect(x: base.x - h * 0.13, y: base.y - h * 0.4, width: h * 0.26, height: h * 0.34)), with: .color(Self.cream))
        for side in [-1.0, 1.0] {
            for y in [0.38, 0.26] {
                layer.stroke(line(point(side * 0.23, y), point(side * 0.15, y - 0.02)), with: .color(Self.stripe), style: thin)
            }
            layer.fill(Path(ellipseIn: CGRect(x: base.x + side * h * 0.12 - h * 0.08, y: base.y - h * 0.09, width: h * 0.16, height: h * 0.09)), with: .color(Self.cream))
        }

        // Collar keeps each figure's own colour.
        layer.fill(Path(roundedRect: CGRect(x: base.x - h * 0.17, y: base.y - h * 0.5, width: h * 0.34, height: h * 0.055), cornerRadius: h * 0.025), with: .color(tint))

        // Ears, head, face.
        for (ear, inner) in zip(parts.ears, parts.innerEars) {
            layer.fill(Path(ellipseIn: ear), with: .color(Self.fur))
            layer.fill(Path(ellipseIn: inner), with: .color(Self.stripe))
        }
        layer.fill(Path(ellipseIn: parts.head), with: .color(Self.fur))
        layer.stroke(line(point(0, 0.89), point(0, 0.81)), with: .color(Self.stripe), style: thin)
        layer.stroke(line(point(-0.07, 0.88), point(-0.05, 0.82)), with: .color(Self.stripe), style: thin)
        layer.stroke(line(point(0.07, 0.88), point(0.05, 0.82)), with: .color(Self.stripe), style: thin)
        for side in [-1.0, 1.0] {
            layer.stroke(line(point(side * 0.255, 0.71), point(side * 0.18, 0.69)), with: .color(Self.stripe), style: thin)
            layer.stroke(line(point(side * 0.25, 0.63), point(side * 0.18, 0.64)), with: .color(Self.stripe), style: thin)
        }
        layer.fill(Path(ellipseIn: CGRect(x: base.x - h * 0.14, y: base.y - h * 0.68, width: h * 0.28, height: h * 0.17)), with: .color(Self.cream))
        let eye = h * 0.065
        for side in [-1.0, 1.0] {
            let eyeRect = CGRect(x: base.x + side * h * 0.1 - eye / 2, y: base.y - h * 0.75, width: eye, height: eye)
            layer.fill(Path(ellipseIn: eyeRect), with: .color(Self.stripe))
            layer.fill(Path(ellipseIn: CGRect(x: eyeRect.minX + eye * 0.2, y: eyeRect.minY + eye * 0.15, width: eye * 0.35, height: eye * 0.35)), with: .color(.white))
        }
        var nose = Path()
        nose.move(to: point(-0.04, 0.655))
        nose.addLine(to: point(0.04, 0.655))
        nose.addLine(to: point(0, 0.61))
        nose.closeSubpath()
        layer.fill(nose, with: .color(Self.stripe))

        layer.fill(Path(roundedRect: stand, cornerRadius: 2), with: .color(AppTheme.textPrimary.opacity(0.6)))
    }

    static func slot(at point: CGPoint, in size: CGSize, columns: Int, rows: Int) -> Int {
        let cols = max(columns, 1)
        let rowCount = max(rows, 1)
        let col = min(cols - 1, max(0, Int(point.x / max(size.width, 1) * CGFloat(cols))))
        let row = min(rowCount - 1, max(0, Int(point.y / max(size.height, 1) * CGFloat(rowCount))))
        return row * cols + col
    }
}

#Preview {
    ShelfMark(columns: 4, rows: 2, figures: [0: .green, 1: .pink, 4: .orange], target: 2, ghost: .blue)
        .frame(height: 220)
        .padding()
}
