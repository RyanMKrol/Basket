import SwiftUI

/// A one-shot, full-screen "you got everything!" moment, played when the last
/// item on the to-get list is checked off. Bigger and warmer than the per-item
/// spark burst. Respects Reduce Motion (a calm fade instead of flying sparks).
struct ClearedCelebration: View {
    var reduceMotion: Bool = false

    @State private var shown = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                if !reduceMotion {
                    SparkleBurst(color: Color(red: 1.0, green: 0.74, blue: 0.12),
                                 count: 16, radius: 130)
                }
                Text("🎉")
                    .font(.system(size: 66))
                    .scaleEffect(shown ? 1 : 0.4)
                    .opacity(shown ? 1 : 0)
                    .accessibilityHidden(true)
            }
            Text("All done!")
                .font(Theme.title(26, weight: .bold))
                .foregroundStyle(Theme.onPaper)
                .opacity(shown ? 1 : 0)
        }
        .onAppear {
            withAnimation(reduceMotion ? .easeIn(duration: 0.35)
                                       : .spring(response: 0.5, dampingFraction: 0.6)) {
                shown = true
            }
        }
        .allowsHitTesting(false)
    }
}
