import Foundation
import SwiftData

/// A record that the user has marked a knot as mastered. One per knot id.
/// Stored locally on-device via SwiftData.
@Model
final class MasteredKnot {
    var knotID: String = ""
    var masteredAt: Date = Date.now

    init(knotID: String = "", masteredAt: Date = .now) {
        self.knotID = knotID
        self.masteredAt = masteredAt
    }
}
