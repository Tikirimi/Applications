import ActivityKit
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            DesignerView()
        }
    }
}

struct DesignerView: View {
    @State private var title = "进行中"
    @State private var subtitle = "一个安静的实时活动"
    @State private var progress: Double = 0.35
    @State private var showProgress = true
    @State private var symbol = "circle.dashed"
    @State private var activity: Activity<DesignActivityAttributes>?
    @State private var note = "未启动"

    private let symbols = [
        "circle.dashed", "square.stack.3d.up", "waveform",
        "hourglass", "moon.stars", "leaf"
    ]

    private var state: DesignActivityAttributes.ContentState {
        DesignActivityAttributes.ContentState(
            title: title,
            subtitle: subtitle,
            progress: progress,
            showProgress: showProgress,
            symbol: symbol
        )
    }

    private var percent: String {
        "\(Int((progress * 100).rounded()))%"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    preview
                    editor
                    actions
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 44)
            }
            .background(Palette.canvas.ignoresSafeArea())
            .navigationTitle("实时活动")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - 预览

    private var preview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("预览")
                .font(.footnote)
                .foregroundStyle(Palette.muted)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    Image(systemName: symbol)
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(Palette.ink)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title.isEmpty ? "标题" : title)
                            .font(.headline)
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(Palette.muted)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)

                    if showProgress {
                        Text(percent)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Palette.muted)
                    }
                }

                if showProgress {
                    ProgressView(value: progress)
                        .tint(Palette.ink)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: 0.5)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 编辑区

    private var editor: some View {
        VStack(spacing: 0) {
            fieldRow("标题") {
                TextField("标题", text: $title)
            }

            hairline

            fieldRow("副标题") {
                TextField("副标题", text: $subtitle)
            }

            hairline

            HStack(spacing: 14) {
                Text("进度")
                    .foregroundStyle(Palette.muted)
                    .frame(width: 56, alignment: .leading)

                Slider(value: $progress, in: 0...1)
                    .tint(Palette.ink)

                Text(percent)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Palette.muted)
                    .frame(width: 40, alignment: .trailing)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            hairline

            HStack(spacing: 14) {
                Text("进度条")
                    .foregroundStyle(Palette.muted)
                    .frame(width: 56, alignment: .leading)

                Spacer(minLength: 0)

                Toggle("", isOn: $showProgress)
                    .labelsHidden()
                    .tint(Palette.ink)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            hairline

            VStack(alignment: .leading, spacing: 14) {
                Text("图标")
                    .foregroundStyle(Palette.muted)

                HStack(spacing: 10) {
                    ForEach(symbols, id: \.self) { name in
                        Button {
                            symbol = name
                        } label: {
                            Image(systemName: name)
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 40, height: 40)
                                .foregroundStyle(symbol == name ? Palette.canvas : Palette.ink)
                                .background(
                                    Circle().fill(symbol == name ? Palette.ink : Palette.fill)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Palette.surface)
        )
    }

    private func fieldRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 14) {
            Text(label)
                .foregroundStyle(Palette.muted)
                .frame(width: 56, alignment: .leading)
            content()
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var hairline: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(height: 0.5)
            .padding(.leading, 18)
    }

    // MARK: - 操作

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                start()
            } label: {
                Text("启动实时活动")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(Palette.canvas)
                    .background(Capsule().fill(Palette.ink))
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                secondaryButton("更新内容") { update() }
                secondaryButton("结束活动") { end() }
            }

            Text(note)
                .font(.footnote)
                .foregroundStyle(Palette.muted)
                .padding(.top, 4)
        }
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(Palette.ink)
                .background(Capsule().fill(Palette.fill))
        }
        .buttonStyle(.plain)
    }

    // MARK: - ActivityKit

    private func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            note = "系统未允许实时活动，请到 设置 → 通知 打开"
            return
        }
        let content = state
        Task { @MainActor in
            do {
                let newActivity = try Activity.request(
                    attributes: DesignActivityAttributes(),
                    content: ActivityContent(state: content, staleDate: nil),
                    pushType: nil
                )
                activity = newActivity
                note = "已启动，去看锁屏或灵动岛"
            } catch {
                note = "启动失败：\(error.localizedDescription)"
            }
        }
    }

    private func update() {
        guard let activity else {
            note = "还没有活动，先启动一个"
            return
        }
        let content = state
        Task { @MainActor in
            await activity.update(ActivityContent(state: content, staleDate: nil))
            note = "内容已更新"
        }
    }

    private func end() {
        guard let activity else {
            note = "还没有活动"
            return
        }
        Task { @MainActor in
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
            note = "活动已结束"
        }
    }
}
