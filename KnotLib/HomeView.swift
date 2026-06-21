import SwiftUI

/// The library home: a header with the mastered count, a daily-drill entry, then the full
/// list of knots (free ones open; Pro ones show a lock until unlocked).
struct HomeView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var library: LibraryModel

    @State private var showSettings = false
    @State private var showDrill = false
    @State private var showPaywall = false
    @State private var search = ""

    private var catalog: KnotCatalog { library.catalog }

    private var filtered: [Knot] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return catalog.all }
        return catalog.all.filter {
            $0.name.lowercased().contains(q) || $0.category.lowercased().contains(q)
            || $0.useCase.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KnotLibBackground()
                List {
                    headerSection
                    drillSection
                    knotsSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .searchable(text: $search, prompt: "Search knots")
            }
            .navigationTitle("Knot Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap(); showSettings = true
                    } label: {
                        Image(systemName: "gearshape").accessibilityLabel("Settings")
                    }
                    .accessibilityIdentifier("settings-button")
                }
            }
            .tint(Color.klAccent)
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .navigationDestination(isPresented: $showDrill) { DrillView() }
        }
    }

    // MARK: Sections

    private var headerSection: some View {
        Section {
            HStack(spacing: 12) {
                MetricTile(value: "\(library.masteredCount)", label: "Mastered")
                MetricTile(value: "\(library.totalKnots)", label: "Knots")
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var drillSection: some View {
        Section {
            Button {
                Haptics.tap()
                if store.isPro { showDrill = true } else { showPaywall = true }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.klAccent)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Drill").font(.headline).foregroundStyle(.primary)
                        Text(store.isPro ? "Today: \(library.todaysDrillKnot()?.name ?? "—")"
                                         : "Build muscle memory. Pro feature.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: store.isPro ? "chevron.right" : "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("drill-entry")
        }
    }

    private var knotsSection: some View {
        Section("All Knots") {
            ForEach(filtered) { knot in
                let locked = !catalog.canOpen(knot, isPro: store.isPro)
                Button {
                    Haptics.tap()
                    if locked { showPaywall = true } else { open(knot) }
                } label: {
                    KnotRow(knot: knot, locked: locked, mastered: library.isMastered(knot))
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(item: $opened) { knot in
            KnotDetailView(knot: knot)
        }
    }

    @State private var opened: Knot?
    private func open(_ knot: Knot) { opened = knot }
}
