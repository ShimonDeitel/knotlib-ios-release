import Foundation

/// One knot in the library. Pure value type, decoded from the bundled `knots.json`.
/// Content (names, use cases, step instructions) is factual public-domain knot-tying technique.
struct Knot: Identifiable, Equatable, Hashable, Decodable {
    let id: String
    let name: String
    let useCase: String
    let category: String
    let difficulty: Int          // 1...3
    let free: Bool               // true = available without Pro
    let diagram: DiagramKind
    let steps: [String]

    var isPro: Bool { !free }
    var stepCount: Int { steps.count }

    var difficultyLabel: String {
        switch difficulty {
        case 1: return "Easy"
        case 2: return "Intermediate"
        default: return "Advanced"
        }
    }
}

/// Which schematic Canvas drawing to render for a knot. Decoded as a string; unknown
/// values fall back to a generic loop so new data can never crash an older binary.
enum DiagramKind: String, Decodable, CaseIterable {
    case loopThrough
    case figureEight
    case square
    case bowline
    case cloveHitch
    case twoHalfHitches
    case sheetBend
    case tautLine
    case figureEightLoop
    case alpineButterfly
    case prusik
    case doubleFishermans
    case rollingHitch
    case truckerHitch
    case constrictor
    case timberHitch
    case cleatHitch
    case anchorBend
    case slipKnot
    case carrickBend
    case waterKnot

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = DiagramKind(rawValue: raw) ?? .loopThrough
    }
}

/// Top-level shape of `knots.json`.
struct KnotLibrary: Decodable {
    let version: Int
    let knots: [Knot]
}
