import SwiftUI

/// The inline quantity stepper that slides down inside a row's card when you tap
/// it. A − / value / + stepper, an optional unit toggle (g↔kg, ml↔L) and a clear
/// button. Purely presentational: all the maths lives in `Measure`.
struct QuantityEditor: View {
    let value: Double
    let unit: MeasureUnit
    let onStep: (_ up: Bool) -> Void
    let onToggleUnit: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            stepButton("minus", up: false)
            Text(Measure.format(value, unit: unit))
                .font(Theme.body(16, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .frame(minWidth: 84)
            stepButton("plus", up: true)

            Spacer(minLength: 8)

            if Measure.hasAlternateScale(unit) {
                Button(action: onToggleUnit) {
                    Text(alternateLabel)
                        .font(Theme.body(13, weight: .semibold))
                        .foregroundStyle(Theme.leaf)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.leaf.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Button(action: onClear) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(width: 30, height: 30)
                    .background(Theme.inkSoft.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 12)
    }

    /// The scale you'd switch to (shown on the toggle button).
    private var alternateLabel: String {
        switch unit {
        case .gram:       return "kg"
        case .kilogram:   return "g"
        case .milliliter: return "L"
        case .liter:      return "ml"
        case .count:      return ""
        }
    }

    private func stepButton(_ systemName: String, up: Bool) -> some View {
        Button { onStep(up) } label: {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Theme.leaf, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
