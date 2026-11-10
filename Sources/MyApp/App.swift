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
    @State private var photoItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var imageBase64 = ""
    @State private var activity: Activity<DesignActivityAttributes>?
    @State private var note = ""

    private var state: DesignActivityAttributes.ContentState {
        DesignActivityAttributes.ContentState(
            title: title,
            subtitle: subtitle,
            imageBase64: imageBase64
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    preview
                    copyEditor
                    imageEditor
                    actions
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
            .background(Palette.canvas.ignoresSafeArea())
            .toolbarBackground(Palette.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("实时活动")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - 预览（有图 / 无图 两套排版）

    private var preview: some View {
        VStack(alignment: .leading, spacing: 16) {
            label("预览")

            Group {
                if let image {
                    HStack(alignment: .center, spacing: 16) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))

                        texts
                    }
                } else {
                    texts
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.isEmpty ? "标题" : title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(subtitle.isEmpty ? "副标题" : subtitle)
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 文案

    private var copyEditor: some View {
        VStack(spacing: 0) {
            row("标题") {
                TextField("标题", text: $title)
                    .foregroundStyle(Palette.ink)
            }

            hairline

            row("副标题") {
                TextField("副标题", text: $subtitle)
                    .foregroundStyle(Palette.ink)
            }
        }
    }

    // MARK: - 图片

    private var imageEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            label("图片")

            HStack(spacing: 16) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Text(image == nil ? "没有图片时只显示两行文字" : "有图片时左侧显示封面")
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)

                Spacer(minLength: 0)
            }

            HStack(spacing: 22) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Text(image == nil ? "选择照片" : "更换照片")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Palette.ink)
                }

                if image != nil {
                    Button {
                        clearImage()
                    } label: {
                        Text("移除")
                            .font(.subheadline)
                            .foregroundStyle(Palette.muted)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { @MainActor in await loadImage(from: item) }
        }
    }

    // MARK: - 操作

    private var actions: some View {
        VStack(alignment: .leading, spacing: 20) {
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

            HStack(spacing: 24) {
                Button {
                    update()
                } label: {
                    Text("更新内容")
                        .font(.subheadline)
                        .foregroundStyle(Palette.ink)
                }
                .buttonStyle(.plain)

                Button {
                    end()
                } label: {
                    Text("结束活动")
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                }
                .buttonStyle(.plain)
            }

            if !note.isEmpty {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
            }
        }
    }

    // MARK: - 小工具

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(Palette.muted)
    }

    private func row<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
                .frame(width: 56, alignment: .leading)
            content()
        }
        .padding(.vertical, 16)
    }

    private var hairline: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(height: 0.5)
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
        note = "图片已就绪（\(max(1, thumb.count / 1024)) KB）"
    }

    private func clearImage() {
        image = nil
        imageBase64 = ""
        photoItem = nil
        note = "已移除图片"
    }

    /// 实时活动状态有 4KB 上限，只能放缩略图：逐步压到 ≤1600 字节。
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
