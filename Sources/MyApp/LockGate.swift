import LocalAuthentication
import SwiftUI

/// 冷启动先验证身份：Face ID 优先，失败回落到设备密码。
struct RootView: View {
    @State private var unlocked = false
    @State private var busy = false
    @State private var message = ""

    var body: some View {
        ZStack {
            if unlocked {
                DesignerView()
            } else {
                lockScreen
            }
        }
        .onAppear(perform: authenticate)
    }

    private var lockScreen: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "faceid")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Palette.ink)

                Text("实时活动")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.ink)

                Text(message.isEmpty ? "验证身份后继续" : message)
                    .font(.footnote)
                    .foregroundStyle(Palette.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button {
                    authenticate()
                } label: {
                    Text("解锁")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 140)
                        .padding(.vertical, 10)
                        .foregroundStyle(Palette.canvas)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Palette.ink)
                        )
                }
                .buttonStyle(.plain)
                .disabled(busy)
                .opacity(busy ? 0.4 : 1)
                .padding(.top, 8)
            }
        }
    }

    private func authenticate() {
        guard !busy else { return }

        busy = true
        message = ""

        let context = LAContext()
        context.localizedFallbackTitle = "使用设备密码"
        context.localizedCancelTitle = "取消"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            busy = false
            message = "这台设备没有设置面容 ID 或锁屏密码"
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "解锁实时活动设计器"
        ) { success, _ in
            DispatchQueue.main.async {
                busy = false
                if success {
                    unlocked = true
                } else {
                    message = "验证未通过，点「解锁」重试"
                }
            }
        }
    }
}
