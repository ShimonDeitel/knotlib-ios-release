import SwiftUI

/// The daily muscle-memory drill (Pro). Picks today's knot deterministically and walks the user
/// through its steps one at a time, hands-on, then lets them mark it mastered.
struct DrillView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var library: LibraryModel

    @State private var step = 0
    @State private var knot: Knot?

    var body: some View {
        ZStack {
            KnotLibBackground()
            if let knot {
                content(knot)
            } else {
                ContentUnavailableView("No knot today",
                                       systemImage: "figure.strengthtraining.traditional",
                                       description: Text("Check back tomorrow for a new drill."))
            }
        }
        .navigationTitle("Daily Drill")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color.klAccent)
        .onAppear { if knot == nil { knot = library.todaysDrillKnot() } }
    }

    private func content(_ knot: Knot) -> some View {
        VStack(spacing: 20) {
            KnotDiagram(kind: knot.diagram)
                .padding(20)
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .background(Color.klCard, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text(knot.name).font(.title2.weight(.bold))

            // Progress dots.
            HStack(spacing: 6) {
                ForEach(0..<knot.steps.count, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Color.klAccent : Color.klCard)
                        .frame(width: i == step ? 22 : 8, height: 8)
                        .animation(.easeOut(duration: 0.2), value: step)
                }
            }

            StepRow(index: step + 1, text: knot.steps[clamped(step, in: knot)], highlighted: true)
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.klCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .id(step)
                .transition(.opacity)

            Spacer()

            controls(knot)
        }
        .padding()
    }

    @ViewBuilder
    private func controls(_ knot: Knot) -> some View {
        let isLast = step >= knot.steps.count - 1
        HStack(spacing: 12) {
            Button {
                Haptics.tap()
                withAnimation { step = max(0, step - 1) }
            } label: {
                Text("Back").frame(maxWidth: .infinity).padding(.vertical, 4)
            }
            .softButton()
            .disabled(step == 0)
            .opacity(step == 0 ? 0.5 : 1)

            if isLast {
                Button {
                    Haptics.success()
                    library.toggleMastered(knot)
                } label: {
                    HStack {
                        Image(systemName: library.isMastered(knot) ? "checkmark.seal.fill" : "seal")
                        Text(library.isMastered(knot) ? "Mastered" : "Mark Mastered")
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .prominentButton()
                .accessibilityIdentifier("drill-master")
            } else {
                Button {
                    Haptics.tap()
                    withAnimation { step = min(knot.steps.count - 1, step + 1) }
                } label: {
                    Text("Next").frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .prominentButton()
                .accessibilityIdentifier("drill-next")
            }
        }
    }

    private func clamped(_ i: Int, in knot: Knot) -> Int {
        min(max(0, i), knot.steps.count - 1)
    }
}
