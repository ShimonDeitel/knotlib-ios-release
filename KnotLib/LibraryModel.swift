import Foundation
import SwiftData
import SwiftUI

/// App state: owns the SwiftData store and the in-memory knot catalog, tracks which knots are
/// mastered, and derives the mastered count. Mastery is stored locally on-device only.
@MainActor
final class LibraryModel: ObservableObject {
    let container: ModelContainer
    let catalog: KnotCatalog
    weak var store: Store?

    @Published private(set) var masteredIDs: Set<String> = []

    init(container: ModelContainer, catalog: KnotCatalog = .loadBundled()) {
        self.container = container
        self.catalog = catalog
        refresh()
    }

    // MARK: Container (local-only, on-device persistence)

    static func makeContainer() -> ModelContainer {
        let schema = Schema([MasteredKnot.self])
        let local = ModelConfiguration(schema: schema)
        if let c = try? ModelContainer(for: schema, configurations: local) { return c }
        // Last resort so the app never crashes on launch.
        let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: mem)
    }

    // MARK: Derived data

    var totalKnots: Int { catalog.all.count }
    var masteredCount: Int { masteredIDs.count }

    func isMastered(_ knot: Knot) -> Bool { masteredIDs.contains(knot.id) }

    /// Mastery is a Pro feature. Free users can browse free knots but cannot record mastery.
    func canMaster(_ knot: Knot) -> Bool {
        store?.isPro == true && catalog.canOpen(knot, isPro: store?.isPro == true)
    }

    // MARK: Mutations

    func refresh() {
        let all = (try? container.mainContext.fetch(FetchDescriptor<MasteredKnot>())) ?? []
        masteredIDs = Set(all.map { $0.knotID })
    }

    /// Toggle a knot's mastered state. No-ops (defense in depth) if the user isn't Pro.
    func toggleMastered(_ knot: Knot) {
        guard store?.isPro == true else { return }
        let ctx = container.mainContext
        if masteredIDs.contains(knot.id) {
            let id = knot.id
            let existing = (try? ctx.fetch(FetchDescriptor<MasteredKnot>(
                predicate: #Predicate { $0.knotID == id }))) ?? []
            existing.forEach { ctx.delete($0) }
        } else {
            ctx.insert(MasteredKnot(knotID: knot.id))
        }
        try? ctx.save()
        refresh()
    }

    /// Erase all on-device mastery data (used by Delete Account).
    func deleteAllData() {
        let ctx = container.mainContext
        try? ctx.delete(model: MasteredKnot.self)
        try? ctx.save()
        refresh()
    }

    // MARK: Daily drill

    /// The knot featured in today's drill, given the user's Pro state.
    func todaysDrillKnot() -> Knot? {
        catalog.drillKnot(isPro: store?.isPro == true, dayIndex: dayIndex())
    }
}
