import SwiftUI
import StoreKit

/// A small "about" sheet reached from the ⓘ in the list header: app name,
/// version, and an in-app tip jar. The natural future home for a sound toggle or
/// theme picker. Basket is free; tipping is entirely optional and unlocks nothing.
struct AboutView: View {
    @Environment(TipJar.self) private var tipJar

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
                    .accessibilityHidden(true)

                Text("Basket")
                    .font(Theme.title(32, weight: .bold))
                    .foregroundStyle(Theme.onPaper)
                    .accessibilityAddTraits(.isHeader)

                Text("A soft, friendly shopping list.\nOn your device, and nowhere else.")
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.onPaperSoft)
                    .multilineTextAlignment(.center)

                tipSection
                    .padding(.top, 6)

                Spacer()

                Text(version)
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.onPaperSoft.opacity(0.7))
                    .padding(.bottom, 14)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task { await tipJar.load() }
    }

    @ViewBuilder private var tipSection: some View {
        VStack(spacing: 10) {
            Text("Enjoying Basket? Leave a tip ☕")
                .font(Theme.body(14, weight: .medium))
                .foregroundStyle(Theme.onPaperSoft)

            switch tipJar.state {
            case .idle, .loading:
                ProgressView().tint(Theme.leaf).frame(height: 86)
            case .unavailable:
                Text("Tips aren't available right now.")
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.onPaperSoft)
                    .frame(height: 86)
            case .loaded:
                HStack(spacing: 12) {
                    ForEach(tipJar.products, id: \.id, content: tipButton)
                }
            }

            if tipJar.thanked {
                Text("Thank you! 💚")
                    .font(Theme.body(14, weight: .semibold))
                    .foregroundStyle(Theme.leaf)
            } else if tipJar.hasTipped {
                Text("Thanks for supporting Basket ♥")
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.onPaperSoft.opacity(0.85))
            }
        }
    }

    private func tipButton(_ product: Product) -> some View {
        let badge = TipJar.badge(for: product.id)
        let busy = tipJar.purchasingID == product.id
        return Button {
            Task { await tipJar.tip(product) }
        } label: {
            VStack(spacing: 3) {
                Text(badge.emoji).font(.system(size: 24))
                Text(badge.label).font(Theme.body(13, weight: .semibold))
                Text(product.displayPrice).font(Theme.body(11)).opacity(0.9)
            }
            .foregroundStyle(.white)
            .frame(width: 82, height: 86)
            .background(Theme.leaf, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                if busy {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.black.opacity(0.25))
                        ProgressView().tint(.white)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(tipJar.purchasingID != nil)
        .opacity(tipJar.purchasingID != nil && !busy ? 0.5 : 1)
        .accessibilityLabel("\(badge.label) tip, \(product.displayPrice)\(busy ? ", purchasing" : "")")
        .accessibilityHint("Leaves a tip — doesn't unlock anything")
    }
}
