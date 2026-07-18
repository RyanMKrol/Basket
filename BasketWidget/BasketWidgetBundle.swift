import SwiftUI
import WidgetKit

@main
struct BasketWidgetBundle: WidgetBundle {
    var body: some Widget {
        BasketWidget()
        BasketAddWidget()
        BasketCombinedWidget()
    }
}
