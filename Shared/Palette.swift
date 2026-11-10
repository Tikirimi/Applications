import SwiftUI
import UIKit

/// 只有黑白灰：全部走系统语义色，深色/浅色模式自动切换。
enum Palette {
    /// 页面底色
    static var canvas: Color { Color(uiColor: .systemGroupedBackground) }
    /// 卡片底色
    static var surface: Color { Color(uiColor: .secondarySystemGroupedBackground) }
    /// 次级卡片 / 未选中控件
    static var fill: Color { Color(uiColor: .tertiarySystemFill) }
    /// 主文字
    static var ink: Color { Color(uiColor: .label) }
    /// 次要文字
    static var muted: Color { Color(uiColor: .secondaryLabel) }
    /// 分隔线
    static var hairline: Color { Color(uiColor: .separator) }
}
