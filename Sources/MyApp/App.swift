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
    @State private var title = "设计进行中"
    @State private var subtitle = "拖动滑块看看效果"
    @State private var progress: Double = 0.35
    @State private var showProgress = true
    @State private var symbol = "paintpalette.fill"
    @State private var themeHex = "4F7CFF"
    @State private var activity: Activity<DesignActivityAttributes>?
    @State private var status = "未启动"

    private let symbolChoices = [
        "paintpalette.fill", "sparkles", "hammer.fill",
        "clock.fill", "flame.fill", "leaf.fill", "bolt.fill"
    ]
    private let colorChoices = ["4F7CFF", "FF5A5F", "34C759", "FF9500", "AF52DE", "00C7BE"]

    private var contentState: DesignActivityAttributes.ContentState {
        DesignActivityAttributes.ContentState(
            title: title,
            subtitle: subtitle,
            progress: progress,
            showProgress: showProgress,
            themeHex: "#" + themeHex,
            symbol: symbol
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("预览") {
                    previewCard
                }

                Section("文案") {
                    TextField("标题", text: $title)
                    TextField("副标题", text: $subtitle)
                }

                Section("样式") {
                    Toggle("显示进度条", isOn: $showProgress)

                    if showProgress {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("进度")
                                Spacer()
                                Text("\(Int((progress * 100).rounded()))%")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $progress, in: 0...1)
                        }
                        .padding(.vertical, 4)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(symbolChoices, id: \.self) { name in
                                Button {
                                    symbol = name
                                } label: {
                                    Image(systemName: name)
                                        .font(.title3)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(hex: themeHex).opacity(symbol == name ? 0.25 : 0.08))
                                        )
                                        .foregroundStyle(Color(hex: themeHex))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    HStack(spacing: 12) {
                        ForEach(colorChoices, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle().strokeBorder(
                                        Color.primary.opacity(themeHex == hex ? 0.9 : 0),
                                        lineWidth: 2
                                    )
                                )
                                .onTapGesture { themeHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button("启动实时活动") { start() }
                    Button("更新内容") { update() }
                    Button("结束活动") { end() }
                        .foregroundStyle(.red)
                } header: {
                    Text("控制")
                } footer: {
                    Text(status)
                }
            }
            .navigationTitle("实时活动设计器")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var previewCard: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(Color(hex: themeHex))

            VStack(alignment: .leading, spacing: 2) {
                Text(title.isEmpty ? "标题" : title)
                    .font(.headline)
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if showProgress {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: themeHex).opacity(0.18))
        )
        .listRowInsets(EdgeInsets())
    }

    private func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            status = "系统里没有允许实时活动，请到 设置 → 通知 里打开"
            return
        }
        let state = contentState
        Task { @MainActor in
            do {
                let newActivity = try Activity.request(
                    attributes: DesignActivityAttributes(),
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
                activity = newActivity
                status = "已启动，去看锁屏或灵动岛"
            } catch {
                status = "启动失败：\(error.localizedDescription)"
            }
        }
    }

    private func update() {
        guard let activity else {
            status = "还没有活动，先启动一个"
            return
        }
        let state = contentState
        Task { @MainActor in
            await activity.update(ActivityContent(state: state, staleDate: nil))
            status = "内容已更新"
        }
    }

    private func end() {
        guard let activity else {
            status = "还没有活动"
            return
        }
        Task { @MainActor in
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
            status = "活动已结束"
        }
    }
}
