import XCTest
import SwiftData
@testable import KnotLib

/// Tests for the live LibraryModel: mastery tracking, Pro gating (defense-in-depth), and the
/// SwiftData-backed mastered count. Uses an in-memory store so nothing touches CloudKit or disk.
@MainActor
final class LibraryModelTests: XCTestCase {

    private func memoryContainer() -> ModelContainer {
        try! ModelContainer(for: MasteredKnot.self,
                            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func catalog() -> KnotCatalog {
        KnotCatalog(knots: [
            Knot(id: "free1", name: "Free One", useCase: "u", category: "Loop",
                 difficulty: 1, free: true, diagram: .bowline, steps: ["a", "b"]),
            Knot(id: "pro1", name: "Pro One", useCase: "u", category: "Hitch",
                 difficulty: 2, free: false, diagram: .cloveHitch, steps: ["a", "b"])
        ])
    }

    func testMasteryRequiresProAndPersists() {
        let store = Store()
        let model = LibraryModel(container: memoryContainer(), catalog: catalog())
        model.store = store

        let free = model.catalog.knot(id: "free1")!
        XCTAssertEqual(model.masteredCount, 0)

        // Not Pro -> toggling must not record anything.
        model.toggleMastered(free)
        XCTAssertEqual(model.masteredCount, 0, "free users cannot mark mastered")
        XCTAssertFalse(model.isMastered(free))
    }

    func testMasteryTogglesWhenProForced() {
        // Use the DEBUG force-pro hook so this is deterministic without StoreKit.
        setenv("KNOTLIB_FORCE_PRO", "1", 1)
        defer { unsetenv("KNOTLIB_FORCE_PRO") }

        let store = Store()
        // Give the store a moment to evaluate entitlements (debugForcePro is read in refresh()).
        let exp = expectation(description: "pro")
        Task { @MainActor in
            await store.refreshEntitlements()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)

        let model = LibraryModel(container: memoryContainer(), catalog: catalog())
        model.store = store
        let knot = model.catalog.knot(id: "pro1")!

        model.toggleMastered(knot)
        XCTAssertTrue(model.isMastered(knot))
        XCTAssertEqual(model.masteredCount, 1)

        model.toggleMastered(knot)
        XCTAssertFalse(model.isMastered(knot))
        XCTAssertEqual(model.masteredCount, 0, "toggling again un-masters and removes the record")
    }

    func testDeleteAllDataClearsMastery() {
        setenv("KNOTLIB_FORCE_PRO", "1", 1)
        defer { unsetenv("KNOTLIB_FORCE_PRO") }
        let store = Store()
        let exp = expectation(description: "pro")
        Task { @MainActor in await store.refreshEntitlements(); exp.fulfill() }
        wait(for: [exp], timeout: 2)

        let model = LibraryModel(container: memoryContainer(), catalog: catalog())
        model.store = store
        model.toggleMastered(model.catalog.knot(id: "pro1")!)
        XCTAssertEqual(model.masteredCount, 1)

        model.deleteAllData()
        XCTAssertEqual(model.masteredCount, 0)
    }

    func testTotalKnotsReflectsCatalog() {
        let model = LibraryModel(container: memoryContainer(), catalog: catalog())
        XCTAssertEqual(model.totalKnots, 2)
    }
}
