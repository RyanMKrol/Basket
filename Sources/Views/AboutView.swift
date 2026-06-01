import SwiftUI

/// App metadata kept in one place.
enum AppInfo {
    /// "Tip the developer" link. Free app; tipping is entirely optional.
    static let koFiURL = "https://ko-fi.com/ryankrol"
}

/// A small "about" sheet reached from the ⓘ in the list header: app name,
/// version and a Ko-fi tip link. The natural future home for a sound toggle or
/// theme picker.
struct AboutView: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = info?["CFBundleVersion"] as? String ?? "1"
        return "Version \(v) (\(b))"
    }

    var body: some View {
        ZStack {
            BasketBackground()

            VStack(spacing: 14) {
                Text("🧺")
                    .font(.system(size: 60))
                    .padding(.top, 10)

                Text("Basket")
                    .font(Theme.title(32, weight: .bold))
                    .foregroundStyle(Theme.onPaper)

                Text("A soft, friendly shopping list.\nOn your device, and nowhere else.")
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.onPaperSoft)
                    .multilineTextAlignment(.center)

                if let url = URL(string: AppInfo.koFiURL) {
                    Link(destination: url) {
                        HStack(spacing: 8) {
                            Image(systemName: "cup.and.saucer.fill")
                            Text("Buy the developer a coffee")
                                .font(Theme.body(16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(Theme.leaf, in: Capsule())
                    }
                    .padding(.top, 8)
                }

                Spacer()

                Text(version)
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.onPaperSoft.opacity(0.7))
                    .padding(.bottom, 14)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
