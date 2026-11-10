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
        /// 缩略图的 base64（JPEG）。空串表示没有图片。
        /// 不放在共享容器里，是为了让未签名安装也能用——扩展读不到 App 沙盒。
        var imageBase64: String = ""
    }
}
