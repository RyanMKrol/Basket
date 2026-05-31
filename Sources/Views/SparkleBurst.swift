import SwiftUI

/// A one-shot burst of little pixel sparks flying outward and fading — played
/// when an item is checked off. Plays once on appear.
struct SparkleBurst: View {
    var color: Color = Color(red: 1.0, green: 0.74, blue: 0.12)   // vivid gold
    var count: Int = 8
    var radius: CGFloat = 30

    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = (Double(i) / Double(count)) * 2 * .pi
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(color)
                    .rotationEffect(.degrees(animate ? 120 : 0))
                    .scaleEffect(animate ? 0.2 : 1.1)
                    .opacity(animate ? 0 : 1)
                    .offset(x: animate ? cos(angle) * radius : 0,
                            y: animate ? sin(angle) * radius : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) { animate = true }
        }
        .allowsHitTesting(false)
    }
}
