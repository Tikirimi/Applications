import ActivityKit
import Foundation

struct DesignActivityAttributes: ActivityAttributes {
    var designName: String = "我的实时活动"

    struct ContentState: Codable, Hashable {
        var title: String
        var subtitle: String
        var progress: Double
        var showProgress: Bool
        var themeHex: String
        var symbol: String
    }
}
