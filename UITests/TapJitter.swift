import XCTest

/// A deterministic pseudo-random generator, seeded per test run, so a jitter
/// test failure is reproducible (same seed → same offsets) instead of
/// depending on genuinely random noise nobody can rerun.
struct SeededJitter {
    private var state: UInt64

    init(seed: UInt64) {
        // xorshift64* requires a non-zero state.
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    /// Next pseudo-random value in [-1, 1].
    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        let bucket = state % 2_000_001
        return Double(bucket) / 1_000_000.0 - 1.0
    }
}

extension XCUIElement {
    /// Taps at an offset from dead-center, as a fraction of the element's own
    /// width/height — standing in for a real finger's imprecision. `dx`/`dy`
    /// should stay within roughly ±0.35 so the tap lands inside the element's
    /// own bounds rather than spilling onto a neighbouring control (which
    /// would test "missed the target entirely", not "tapped off-center").
    func tapJittered(dx: Double, dy: Double) {
        coordinate(withNormalizedOffset: CGVector(dx: 0.5 + dx, dy: 0.5 + dy)).tap()
    }
}
