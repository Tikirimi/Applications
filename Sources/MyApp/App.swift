import ActivityKit
import PhotosUI
import SwiftUI
import UIKit

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
    @State private var photoItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var imageBase64 = ""
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
            symbol: symbol,
            imageBase64: imageBase64
        )
    }

    private var percent: String {
        "\(Int((progress * 100).rounded()))%"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    hero
                    contentSection
                    imageSection
                    detailSection
                    actions
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 44)
            }
            .background(Palette.canvas.ignoresSafeArea())
            .navigationTitle("实时活动")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - 预览

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                thumbnail(size: 58)

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
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Palette.hairline, lineWidth: 0.5)
        )
    }

    // MARK: - 内容

    private var contentSection: some View {
        section("内容") {
            VStack(spacing: 0) {
                fieldRow("标题") {
                    TextField("标题", text: $title)
                }

                hairline

                fieldRow("副标题") {
                    TextField("副标题", text: $subtitle)
                }
            }
        }
    }

    // MARK: - 图片

    private var imageSection: some View {
        section("图片") {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    thumbnail(size: 46)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(image == nil ? "未选择图片" : "已选择图片")
                            .foregroundStyle(Palette.ink)
                        Text("会显示在锁屏和灵动岛上")
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)

                hairline

                HStack(spacing: 12) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Text("选择照片")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .foregroundStyle(Palette.canvas)
                            .background(Capsule().fill(Palette.ink))
                    }

                    if image != nil {
                        Button {
                            clearImage()
                        } label: {
                            Text("移除")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .foregroundStyle(Palette.ink)
                                .background(Capsule().fill(Palette.fill))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task { @MainActor in await loadImage(from: item) }
            }
        }
    }

    // MARK: - 细节

    private var detailSection: some View {
        section("细节") {
            VStack(spacing: 0) {
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
                    Text("无图时的图标")
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
        }
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

    // MARK: - 小组件

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(Palette.muted)
                .padding(.leading, 4)

            content()
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Palette.surface)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func thumbnail(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Palette.fill)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            } else {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.38, weight: .regular))
                    .foregroundStyle(Palette.ink)
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - 图片处理

    @MainActor
    private func loadImage(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let picked = UIImage(data: data) else {
            note = "这张图片读不出来"
            return
        }

        image = picked

        guard let thumb = makeThumbnail(from: picked) else {
            imageBase64 = ""
            note = "图片转换失败"
            return
        }

        imageBase64 = thumb.base64EncodedString()
        note = "图片已就绪（\(thumb.count / 1024) KB）"
    }

    private func clearImage() {
        image = nil
        imageBase64 = ""
        photoItem = nil
        note = "已移除图片"
    }

    /// 实时活动的状态有 4KB 上限，图片只能塞缩略图：逐步压到 ≤1600 字节。
    private func makeThumbnail(from image: UIImage) -> Data? {
        let sides: [CGFloat] = [112, 96, 80, 64, 48, 40, 32]
        let qualities: [CGFloat] = [0.6, 0.5, 0.4, 0.3]

        var smallest: Data?

        for side in sides {
            for quality in qualities {
                guard let data = downscale(image, to: side, quality: quality) else { continue }
                if smallest == nil || data.count < (smallest?.count ?? Int.max) {
                    smallest = data
                }
                if data.count <= 1600 {
                    return data
                }
            }
        }

        return smallest
    }

    private func downscale(_ image: UIImage, to side: CGFloat, quality: CGFloat) -> Data? {
        let width = image.size.width
        let height = image.size.height
        guard width > 0, height > 0 else { return nil }

        let factor = min(side / max(width, height), 1)
        let size = CGSize(
            width: max(1, (width * factor).rounded()),
            height: max(1, (height * factor).rounded())
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }

        return scaled.jpegData(compressionQuality: quality)
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
