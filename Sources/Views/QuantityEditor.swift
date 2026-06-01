import SwiftUI

/// The inline quantity editor that slides down inside a row's card when you tap
/// it: a − / value / + stepper on top, and a row of unit pills below (every item
/// can be counted in plain "units"; unrecognised items offer all of ml/L/g/kg).
/// Purely presentational — all the maths lives in `Measure`.
struct QuantityEditor: View {
    let value: Double
    let unit: MeasureUnit
    let units: [MeasureUnit]
    let onStep: (_ up: Bool) -> Void
    let onPickUnit: (MeasureUnit) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                stepButton("minus", up: false)
                Text(Measure.format(value, unit: unit))
                    .font(Theme.body(16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                    .frame(minWidth: 84)
                stepButton("plus", up: true)

                Spacer(minLength: 8)

                Button(action: onClear) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(width: 30, height: 30)
                        .background(Theme.inkSoft.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                ForEach(units, id: \.self) { u in
                    unitPill(u)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.top, 12)
    }

    private func unitPill(_ u: MeasureUnit) -> some View {
        let selected = u == unit
        return Button { onPickUnit(u) } label: {
            Text(u == .count ? "units" : u.symbol)
                .font(Theme.body(13, weight: .semibold))
                .foregroundStyle(selected ? .white : Theme.inkSoft)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Theme.leaf : Theme.inkSoft.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
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
