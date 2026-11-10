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
                VStack(alignment: .leading, spacing: 26) {
                    copyCard
                    imageCard
                    actions
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 48)
            }
            .background(Palette.canvas.ignoresSafeArea())
            .toolbarBackground(Palette.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("实时活动")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - 文案

    private var copyCard: some View {
        card("文案") {
            VStack(spacing: 0) {
                fieldRow("标题") {
                    TextField("标题", text: $title)
                        .foregroundStyle(Palette.ink)
                }

                hairline

                fieldRow("副标题") {
                    TextField("副标题", text: $subtitle)
                        .foregroundStyle(Palette.ink)
                }
            }
        }
    }

    // MARK: - 图片

    private var imageCard: some View {
        card("图片") {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    thumb

                    VStack(alignment: .leading, spacing: 3) {
                        Text(image == nil ? "未选择图片" : "已选择图片")
                            .foregroundStyle(Palette.ink)
                        Text("有图时左图右文，无图只显示两行文字")
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)

                hairline

                HStack(spacing: 10) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Text(image == nil ? "选择照片" : "更换照片")
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
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { @MainActor in await loadImage(from: item) }
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

            HStack(spacing: 10) {
                Button {
                    update()
                } label: {
                    Text("更新内容")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(Palette.ink)
                        .background(Capsule().fill(Palette.fill))
                }
                .buttonStyle(.plain)

                Button {
                    end()
                } label: {
                    Text("结束活动")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(Palette.muted)
                        .background(Capsule().stroke(Palette.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            if !note.isEmpty {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - 小工具

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
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

    private func fieldRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 14) {
            Text(title)
                .foregroundStyle(Palette.muted)
                .frame(width: 56, alignment: .leading)
            content()
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

    @ViewBuilder
    private var thumb: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Palette.fill)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Palette.muted)
                )
        }
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

        guard let thumbnail = makeThumbnail(from: picked) else {
            imageBase64 = ""
            note = "图片转换失败"
            return
        }

        imageBase64 = thumbnail.base64EncodedString()
        note = "图片已就绪（\(max(1, thumbnail.count / 1024)) KB）"
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
