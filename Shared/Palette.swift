import SwiftUI
import UIKit

/// 黑白灰为主，只有页面底色带一点暖调。深色/浅色各自一套，自动跟随系统。
enum Palette {
    private static func rgb(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    /// 页面底色：浅色 #F2F4ED，深色 #141414（近黑的深灰）
    static var canvas: Color {
        dynamic(light: rgb(0xF2F4ED), dark: rgb(0x141414))
    }

    /// 卡片底色：浅色纯白，深色 #1C1C1C
    static var surface: Color {
        dynamic(light: .white, dark: rgb(0x1C1C1C))
    }

    /// 次级控件（未选中的圆形按钮、次按钮）
    static var fill: Color {
        dynamic(light: rgb(0xECEEE6), dark: rgb(0x242424))
    }

    /// 主文字
    static var ink: Color { Color(uiColor: .label) }

    /// 次要文字
    static var muted: Color { Color(uiColor: .secondaryLabel) }

    /// 分隔线
    static var hairline: Color {
        dynamic(light: rgb(0xE2E4DC), dark: rgb(0x2C2C2C))
    }

    /// 进度条底色
    static var track: Color {
        dynamic(light: rgb(0xE2E4DC), dark: rgb(0x3A3A3A))
    }
}
