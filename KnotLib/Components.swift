import SwiftUI

/// A row in the knot library list: a small schematic thumbnail, the name, use case and a status
/// chip (mastered / locked / difficulty). Tapping opens the detail (or the paywall when locked).
struct KnotRow: View {
    let knot: Knot
    let locked: Bool
    let mastered: Bool

    var body: some View {
        HStack(spacing: 14) {
            KnotDiagram(kind: knot.diagram, lineWidth: 4)
                .frame(width: 52, height: 52)
                .background(Color.klCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(knot.name).font(.headline)
                    if mastered {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.klAccent)
                    }
                }
                Text(knot.useCase)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("knot-\(knot.id)")
    }
}

/// A small labelled metric tile (mastered count, total knots) used on Home.
struct MetricTile: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color.klAccent)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.klCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// A numbered step row used on the detail and drill screens.
struct StepRow: View {
    let index: Int
    let text: String
    var highlighted: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(index)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(highlighted ? .white : Color.klAccent)
                .frame(width: 28, height: 28)
                .background(
                    highlighted ? Color.klAccent : Color.klAccent.opacity(0.12),
                    in: Circle()
                )
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Wraps UIActivityViewController so we can share a knot as text.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
