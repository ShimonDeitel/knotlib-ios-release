import Foundation

/// Loads and serves the bundled knot dataset. Pure, dependency-free, and offline.
/// The catalog is decoded once at launch; `free`/`pro` access splits are derived here so the
/// gating rules live in one tested place.
struct KnotCatalog {
    let all: [Knot]

    /// The number of free knots the app advertises (used in copy and the paywall).
    static let freeLimit = 6

    init(knots: [Knot]) {
        self.all = knots
    }

    /// Loads `knots.json` from the app bundle. Falls back to an empty catalog only if the
    /// resource is missing or malformed (the app stays usable rather than crashing).
    static func loadBundled(bundle: Bundle = .main) -> KnotCatalog {
        guard let url = bundle.url(forResource: "knots", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let lib = try? JSONDecoder().decode(KnotLibrary.self, from: data) else {
            return KnotCatalog(knots: [])
        }
        return KnotCatalog(knots: lib.knots)
    }

    var freeKnots: [Knot] { all.filter { $0.free } }
    var proKnots: [Knot] { all.filter { !$0.free } }

    /// Knots the user may open right now, given their Pro state.
    func available(isPro: Bool) -> [Knot] {
        isPro ? all : freeKnots
    }

    /// Knots shown locked in the list for a free user (empty when Pro).
    func locked(isPro: Bool) -> [Knot] {
        isPro ? [] : proKnots
    }

    func knot(id: String) -> Knot? { all.first { $0.id == id } }

    /// A free user can open a free knot; a Pro user can open anything.
    func canOpen(_ knot: Knot, isPro: Bool) -> Bool {
        isPro || knot.free
    }

    /// The drill rotates through the full set for Pro users, free knots otherwise.
    /// Deterministic for a given day so the "daily" drill is stable across launches.
    func drillKnot(isPro: Bool, dayIndex: Int) -> Knot? {
        let pool = available(isPro: isPro)
        guard !pool.isEmpty else { return nil }
        let idx = ((dayIndex % pool.count) + pool.count) % pool.count
        return pool[idx]
    }
}

/// Number of whole days since the reference epoch — used to pick the deterministic daily drill.
func dayIndex(for date: Date = .now, calendar: Calendar = .current) -> Int {
    let start = calendar.startOfDay(for: date)
    let days = calendar.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: start).day ?? 0
    return days
}
