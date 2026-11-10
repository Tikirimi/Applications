import ActivityKit
import Foundation

struct DesignActivityAttributes: ActivityAttributes {
    var designName: String = "Live Activity"

    struct ContentState: Codable, Hashable {
        var title: String
        var subtitle: String
        var progress: Double
        var showProgress: Bool
        var symbol: String
    }
}
