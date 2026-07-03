import SwiftUI

/// The inline quantity editor that slides down inside a row's card when you tap
/// it: a − / value / + stepper on top, and a row of unit pills below (every item
/// can be counted in plain "units"; unrecognised items offer all of ml/L/g/kg).
/// Tap the value itself to type an exact amount on the keyboard, so a big
/// quantity doesn't mean tapping + a hundred times. All the maths lives in
/// `Measure`.
struct QuantityEditor: View {
    let value: Double
    let unit: MeasureUnit
    let units: [MeasureUnit]
    let onStep: (_ up: Bool) -> Void
    let onPickUnit: (MeasureUnit) -> Void
    /// Apply an exact value typed into the field (keyboard entry).
    let onSetValue: (Double) -> Void
    let onClear: () -> Void

    /// While true the value is an editable text field rather than a tappable
    /// label; the buffer holds the in-progress text.
    @State private var editing = false
    @State private var editText = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                stepButton("minus", up: false)
                valueDisplay
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
                .accessibilityLabel("Clear quantity")
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

    /// The number between the − / + buttons: a tappable label normally, swapping
    /// to a focused keyboard field while editing so an exact amount can be typed.
    @ViewBuilder private var valueDisplay: some View {
        if editing {
            HStack(spacing: 4) {
                TextField("", text: $editText)
                    .keyboardType(unit == .count ? .numberPad : .decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($fieldFocused)
                    .font(Theme.body(16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: 40)
                    .onAppear { fieldFocused = true }
                    // Keep the field in step with the − / + buttons while the
                    // keyboard is up: tapping them changes `value`, so mirror the
                    // new amount into the buffer rather than leaving stale text.
                    .onChange(of: value) { _, newValue in
                        if editing { editText = Measure.numberString(newValue) }
                    }
                    // Commit when focus leaves — tapping the X, the row, another
                    // row, or anywhere outside the field. There's deliberately no
                    // on-keyboard Done button (it overlapped the list).
                    .onChange(of: fieldFocused) { _, focused in
                        if !focused { commit() }
                    }
                    .accessibilityLabel("Quantity, \(unitName(unit))")
                if !unit.symbol.isEmpty {
                    Text(unit.symbol)
                        .font(Theme.body(16, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .frame(minWidth: 84)
        } else {
            Text(Measure.format(value, unit: unit))
                .font(Theme.body(16, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .frame(minWidth: 84)
                .contentShape(Rectangle())
                .onTapGesture(perform: beginEditing)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Double tap to type an exact amount")
        }
    }

    /// Full unit name for VoiceOver, since the on-row symbol ("ml", "kg") isn't
    /// always clear read aloud.
    private func unitName(_ u: MeasureUnit) -> String {
        switch u {
        case .count:      return "units"
        case .gram:       return "grams"
        case .kilogram:   return "kilograms"
        case .milliliter: return "millilitres"
        case .liter:      return "litres"
        }
    }

    /// Seed the field with the bare number and switch into edit mode (the field's
    /// `onAppear` takes focus and raises the keyboard).
    private func beginEditing() {
        editText = Measure.numberString(value)
        editing = true
        Haptics.soft()
    }

    /// Leave edit mode, applying the typed value when it parses to something sane
    /// (otherwise the previous amount stands).
    private func commit() {
        guard editing else { return }
        editing = false
        fieldFocused = false
        if let v = Measure.parse(editText, unit: unit) { onSetValue(v) }
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
        .accessibilityLabel(unitName(u))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    /// Plus / minus. While the keyboard is up, step from the *typed* amount — so a
    /// typed 100 + goes to 150, not 550 — snapping to the bucket via `Measure.step`;
    /// the field then follows the new value through `onChange(of: value)`. When not
    /// editing, defer to the parent's stepper as before.
    private func step(_ up: Bool) {
        if editing {
            let base = Measure.parse(editText, unit: unit) ?? value
            onSetValue(Measure.step(base, unit: unit, up: up))
        } else {
            onStep(up)
        }
    }

    private func stepButton(_ systemName: String, up: Bool) -> some View {
        Button { step(up) } label: {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Theme.leaf, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(up ? "Increase quantity" : "Decrease quantity")
    }
}
