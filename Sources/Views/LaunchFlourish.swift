import SwiftUI

/// Fires true exactly once per process launch. Because a SwiftUI scene's root
/// view (and its `@State`) survives background → foreground, seeding state from
/// `consume()` shows the launch flourish only on a true cold start — never on a
/// resume. The static is the belt-and-suspenders: even if the root view is
/// re-initialised, it won't fire twice.
enum LaunchOnce {
    nonisolated(unsafe) static var fired = false
    static func consume() -> Bool {
        if fired { return false }
        fired = true
        return true
    }
}

/// A sub-second welcome shown on cold launch: the basket pops in with a little
/// spark burst, then fades to reveal the list. Reduce Motion gets a calm fade.
struct LaunchFlourish: View {
    var reduceMotion: Bool
    var onFinished: () -> Void

    @State private var appear = false

    var body: some View {
        ZStack {
            BasketBackground()
                .ignoresSafeArea()
            VStack(spacing: 12) {
                ZStack {
                    if !reduceMotion {
                        SparkleBurst(color: Color(red: 1.0, green: 0.74, blue: 0.12),
                                     count: 12, radius: 96)
                    }
                    Text("🧺")
                        .font(.system(size: 88))
                        .scaleEffect(appear ? 1 : 0.5)
                        .opacity(appear ? 1 : 0)
                }
                Text("Basket")
                    .font(Theme.title(30, weight: .bold))
                    .foregroundStyle(Theme.onPaper)
                    .opacity(appear ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? .easeIn(duration: 0.25)
                                       : .spring(response: 0.5, dampingFraction: 0.62)) {
                appear = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.5 : 0.75)) {
                onFinished()
            }
        }
    }
}
