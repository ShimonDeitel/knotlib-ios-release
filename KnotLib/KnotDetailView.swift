import SwiftUI

/// Step-by-step reference for a single knot: a large schematic diagram, the numbered steps,
/// and (Pro) mark-mastered + share.
struct KnotDetailView: View {
    let knot: Knot

    @EnvironmentObject var store: Store
    @EnvironmentObject var library: LibraryModel
    @State private var showPaywall = false
    @State private var showShare = false

    var body: some View {
        ZStack {
            KnotLibBackground()
            ScrollView {
                VStack(spacing: 22) {
                    diagramCard
                    metaRow
                    stepsCard
                    masterButton
                }
                .padding()
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(knot.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    if store.isPro { showShare = true } else { showPaywall = true }
                } label: {
                    Image(systemName: "square.and.arrow.up").accessibilityLabel("Share")
                }
                .accessibilityIdentifier("share-knot")
            }
        }
        .tint(Color.klAccent)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showShare) { ShareSheet(items: [shareText]) }
    }

    private var diagramCard: some View {
        KnotDiagram(kind: knot.diagram)
            .padding(24)
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .background(Color.klCard, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var metaRow: some View {
        HStack(spacing: 10) {
            Label(knot.category, systemImage: "tag")
            Divider().frame(height: 14)
            Label(knot.difficultyLabel, systemImage: "chart.bar")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(knot.useCase)
                .font(.callout)
                .foregroundStyle(.secondary)
            Divider()
            ForEach(Array(knot.steps.enumerated()), id: \.offset) { idx, step in
                StepRow(index: idx + 1, text: step)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.klCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var masterButton: some View {
        let mastered = library.isMastered(knot)
        Button {
            Haptics.success()
            if store.isPro { library.toggleMastered(knot) } else { showPaywall = true }
        } label: {
            HStack {
                Image(systemName: mastered ? "checkmark.seal.fill" : "seal")
                Text(masterLabel(mastered: mastered))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 6)
        }
        .prominentButton()
        .accessibilityIdentifier("master-toggle")
    }

    private func masterLabel(mastered: Bool) -> String {
        if !store.isPro { return "Mark as Mastered (Pro)" }
        return mastered ? "Mastered" : "Mark as Mastered"
    }

    private var shareText: String {
        var lines = ["\(knot.name) — \(knot.useCase)", ""]
        for (i, s) in knot.steps.enumerated() { lines.append("\(i + 1). \(s)") }
        lines.append("")
        lines.append("Learned with Knot Library.")
        return lines.joined(separator: "\n")
    }
}
