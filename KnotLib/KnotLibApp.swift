import SwiftUI
import SwiftData

@main
struct KnotLibApp: App {
    @StateObject private var store: Store
    @StateObject private var library: LibraryModel
    private let container: ModelContainer

    init() {
        let c = LibraryModel.makeContainer()
        let s = Store()
        let m = LibraryModel(container: c)
        m.store = s
        self.container = c
        _store = StateObject(wrappedValue: s)
        _library = StateObject(wrappedValue: m)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(library)
                .modelContainer(container)
        }
    }
}
