import SwiftUI

/// Simple, original schematic line drawings of each knot, rendered with SwiftUI `Canvas`.
/// These are abstract route diagrams (rope paths with over/under crossings), not photos.
/// The accent strand is Apple-blue; the secondary strand is a neutral gray, so every knot
/// reads clearly in both light and dark mode.
struct KnotDiagram: View {
    let kind: DiagramKind
    var lineWidth: CGFloat = 7

    var body: some View {
        Canvas { ctx, size in
            let r = DiagramRenderer(ctx: ctx, size: size, lineWidth: lineWidth)
            r.draw(kind)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Draws each knot kind. All routes are normalized to a unit square then scaled to the canvas,
/// so a single set of point lists describes every diagram.
private struct DiagramRenderer {
    let ctx: GraphicsContext
    let size: CGSize
    let lineWidth: CGFloat

    private var accent: GraphicsContext.Shading { .color(Color(hex: "#007AFF")) }
    private var gray: GraphicsContext.Shading { .color(Color(uiColor: .systemGray2)) }
    private var bg: GraphicsContext.Shading { .color(Color(uiColor: .systemBackground)) }

    private var inset: CGFloat { lineWidth * 1.6 + 8 }

    private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        let w = size.width - inset * 2
        let h = size.height - inset * 2
        return CGPoint(x: inset + x * w, y: inset + y * h)
    }

    /// A smooth rope segment through the given unit points.
    private func strand(_ pts: [(CGFloat, CGFloat)], shading: GraphicsContext.Shading) {
        guard pts.count > 1 else { return }
        var path = Path()
        let points = pts.map { pt($0.0, $0.1) }
        path.move(to: points[0])
        if points.count == 2 {
            path.addLine(to: points[1])
        } else {
            // Catmull-Rom-ish smoothing via quad curves through midpoints.
            for i in 1..<points.count - 1 {
                let mid = CGPoint(x: (points[i].x + points[i + 1].x) / 2,
                                  y: (points[i].y + points[i + 1].y) / 2)
                path.addQuadCurve(to: mid, control: points[i])
            }
            path.addLine(to: points.last!)
        }
        ctx.stroke(path, with: shading,
                   style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }

    /// Punches a "gap" so a crossing strand reads as passing UNDER the one drawn over it.
    private func crossingGap(at unit: (CGFloat, CGFloat), radius: CGFloat = 0.06) {
        let c = pt(unit.0, unit.1)
        let r = radius * min(size.width, size.height)
        let rect = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
        ctx.fill(Path(ellipseIn: rect), with: bg)
    }

    /// A simple post/ring anchor drawn as a rounded bar.
    private func post(x: CGFloat) {
        let top = pt(x, 0.05), bot = pt(x, 0.95)
        var p = Path()
        p.move(to: top); p.addLine(to: bot)
        ctx.stroke(p, with: gray,
                   style: StrokeStyle(lineWidth: lineWidth * 1.6, lineCap: .round))
    }

    private func ring(center: (CGFloat, CGFloat), radius: CGFloat = 0.13) {
        let c = pt(center.0, center.1)
        let r = radius * min(size.width, size.height)
        let rect = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
        ctx.stroke(Path(ellipseIn: rect), with: gray, style: StrokeStyle(lineWidth: lineWidth * 1.4))
    }

    // MARK: Dispatch

    func draw(_ kind: DiagramKind) {
        switch kind {
        case .loopThrough, .slipKnot:      drawOverhand()
        case .figureEight, .figureEightLoop: drawFigureEight(loop: kind == .figureEightLoop)
        case .square, .carrickBend:        drawSquare()
        case .bowline, .alpineButterfly:   drawBowline()
        case .cloveHitch, .constrictor, .timberHitch: drawCloveHitch()
        case .twoHalfHitches, .anchorBend, .rollingHitch: drawTwoHalfHitches()
        case .sheetBend, .waterKnot, .doubleFishermans: drawSheetBend()
        case .tautLine, .prusik, .truckerHitch: drawFrictionHitch()
        case .cleatHitch:                  drawCleat()
        }
    }

    // MARK: Individual schematics

    private func drawOverhand() {
        strand([(0.10, 0.80), (0.30, 0.78), (0.55, 0.40), (0.45, 0.22),
                (0.30, 0.30), (0.40, 0.55), (0.65, 0.62), (0.90, 0.40)], shading: accent)
        crossingGap(at: (0.435, 0.43))
        strand([(0.30, 0.30), (0.40, 0.55)], shading: accent)
    }

    private func drawFigureEight(loop: Bool) {
        strand([(0.12, 0.85), (0.30, 0.70), (0.62, 0.74), (0.70, 0.50),
                (0.50, 0.34), (0.30, 0.46), (0.40, 0.66)], shading: accent)
        crossingGap(at: (0.46, 0.58))
        strand([(0.40, 0.66), (0.60, 0.58), (0.74, 0.30), (0.62, 0.16)], shading: accent)
        if loop {
            strand([(0.62, 0.16), (0.45, 0.12), (0.30, 0.20)], shading: accent)
            ring(center: (0.5, 0.13), radius: 0.05)
        }
    }

    private func drawSquare() {
        strand([(0.08, 0.62), (0.34, 0.60), (0.50, 0.42), (0.66, 0.60), (0.92, 0.58)],
               shading: accent)
        crossingGap(at: (0.50, 0.50))
        strand([(0.08, 0.40), (0.34, 0.42), (0.50, 0.60), (0.66, 0.42), (0.92, 0.42)],
               shading: gray)
    }

    private func drawBowline() {
        // The fixed loop.
        var loop = Path()
        let c = pt(0.40, 0.55)
        let rr = 0.24 * min(size.width, size.height)
        loop.addEllipse(in: CGRect(x: c.x - rr, y: c.y - rr, width: rr * 2, height: rr * 2))
        ctx.stroke(loop, with: accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        // The small fixing knot + standing part.
        strand([(0.62, 0.30), (0.74, 0.45), (0.66, 0.58), (0.55, 0.50),
                (0.66, 0.42), (0.82, 0.40), (0.95, 0.30)], shading: accent)
        crossingGap(at: (0.64, 0.50))
        strand([(0.62, 0.30), (0.74, 0.45)], shading: accent)
    }

    private func drawCloveHitch() {
        post(x: 0.5)
        strand([(0.10, 0.30), (0.50, 0.28), (0.78, 0.40), (0.50, 0.50),
                (0.22, 0.55), (0.50, 0.66), (0.80, 0.72)], shading: accent)
        crossingGap(at: (0.50, 0.50))
        strand([(0.50, 0.50), (0.22, 0.55)], shading: accent)
    }

    private func drawTwoHalfHitches() {
        ring(center: (0.80, 0.5))
        strand([(0.08, 0.5), (0.45, 0.5), (0.62, 0.5)], shading: accent)
        // Two hitches wrapping the standing part.
        strand([(0.40, 0.34), (0.30, 0.5), (0.40, 0.66), (0.50, 0.5), (0.40, 0.34)],
               shading: accent)
        crossingGap(at: (0.40, 0.5))
        strand([(0.55, 0.30), (0.45, 0.5), (0.55, 0.70), (0.65, 0.5), (0.55, 0.30)],
               shading: accent)
    }

    private func drawSheetBend() {
        // Thick rope bight (gray).
        strand([(0.10, 0.30), (0.45, 0.30), (0.58, 0.50), (0.45, 0.70), (0.10, 0.70)],
               shading: gray)
        // Thin rope threading through (accent).
        strand([(0.92, 0.40), (0.60, 0.40), (0.42, 0.52), (0.55, 0.64),
                (0.40, 0.46), (0.50, 0.34)], shading: accent)
        crossingGap(at: (0.50, 0.46))
        strand([(0.40, 0.46), (0.50, 0.34)], shading: accent)
    }

    private func drawFrictionHitch() {
        // Main rope vertical (gray), friction coils around it (accent).
        strand([(0.5, 0.06), (0.5, 0.94)], shading: gray)
        for (i, y) in [0.34, 0.46, 0.58].enumerated() {
            let dir: CGFloat = i.isMultiple(of: 2) ? 1 : -1
            strand([(0.5, CGFloat(y) - 0.06),
                    (0.5 + 0.20 * dir, CGFloat(y)),
                    (0.5, CGFloat(y) + 0.06)], shading: accent)
        }
        strand([(0.5, 0.64), (0.30, 0.80), (0.20, 0.92)], shading: accent)
    }

    private func drawCleat() {
        // Cleat as an H-ish horn shape (gray) with a figure-eight line (accent).
        strand([(0.20, 0.45), (0.80, 0.45)], shading: gray)
        strand([(0.20, 0.35), (0.20, 0.55)], shading: gray)
        strand([(0.80, 0.35), (0.80, 0.55)], shading: gray)
        strand([(0.10, 0.78), (0.30, 0.55), (0.70, 0.40), (0.50, 0.62),
                (0.30, 0.45), (0.70, 0.60), (0.85, 0.40)], shading: accent)
        crossingGap(at: (0.50, 0.51))
        strand([(0.30, 0.45), (0.46, 0.54)], shading: accent)
    }
}
