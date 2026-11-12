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
    @State private var showPicker = false
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
        VStack(spacing: 0) {
            topBar
            list
            bottomBar
        }
        .background(Palette.canvas.ignoresSafeArea())
        .photosPicker(isPresented: $showPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { @MainActor in await loadImage(from: item) }
        }
    }

    // MARK: - 顶栏

    private var topBar: some View {
        HStack(spacing: 6) {
            chip("MyApp")
            Text("/")
                .font(.footnote)
                .foregroundStyle(Palette.caption)
            chip("实时活动")

            Spacer(minLength: 8)

            Menu {
                Button {
                    showPicker = true
                } label: {
                    Label("选择照片", systemImage: "photo")
                }

                if image != nil {
                    Button(role: .destructive) {
                        clearImage()
                    } label: {
                        Label("移除封面", systemImage: "trash")
                    }
                }

                Button(role: .destructive) {
                    end()
                } label: {
                    Label("结束活动", systemImage: "stop.circle")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 30, height: 30)
                    .overlay(Circle().strokeBorder(Palette.ink, lineWidth: 1.5))
            }
        }
        .padding(16)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Palette.chip)
            )
    }

    // MARK: - 列表

    private var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                imageRow
                titleRow
                subtitleRow
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .frame(maxHeight: .infinity)
    }

    private var imageRow: some View {
        Button {
            showPicker = true
        } label: {
            HStack(alignment: .top, spacing: 6) {
                thumb

                VStack(alignment: .leading, spacing: 2) {
                    Text("封面图")
                        .font(.body)
                        .foregroundStyle(Palette.ink)
                    Text(image == nil ? "未选择" : sizeText)
                        .font(.footnote)
                        .foregroundStyle(Palette.caption)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var titleRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField("标题", text: $title)
                .font(.body)
                .foregroundStyle(Palette.ink)
            Text("第一行文字")
                .font(.footnote)
                .foregroundStyle(Palette.caption)
        }
        .padding(.vertical, 16)
    }

    private var subtitleRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField("副标题", text: $subtitle)
                .font(.body)
                .foregroundStyle(Palette.ink)
            Text("第二行文字，留空则只显示一行")
                .font(.footnote)
                .foregroundStyle(Palette.caption)
        }
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var thumb: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipped()
        } else {
            Image(systemName: "photo")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Palette.caption)
                .frame(width: 64, height: 64)
                .background(Palette.chip)
        }
    }

    private var sizeText: String {
        "\(max(1, imageBase64.count / 1024)) KB"
    }

    // MARK: - 底栏

    private var bottomBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !note.isEmpty {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(Palette.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                barButton("启动", filled: true) { start() }
                barButton("更新", filled: false) { update() }
                barButton("结束", filled: false) { end() }
            }
        }
        .padding(8)
        .background(Palette.canvas)
        .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: -4)
    }

    private func barButton(_ label: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(filled ? Palette.canvas : Palette.ink)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(filled ? Palette.ink : Palette.chip)
                )
        }
        .buttonStyle(.plain)
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
        note = "封面已更新（\(max(1, thumbnail.count / 1024)) KB）"
    }

    private func clearImage() {
        image = nil
        imageBase64 = ""
        photoItem = nil
        note = "已移除封面"
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
