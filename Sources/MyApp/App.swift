import ActivityKit
import PhotosUI
import SwiftUI
import UIKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct DesignerView: View {
    @State private var title = "进行中"
    @State private var photoItem: PhotosPickerItem?
    @State private var showPicker = false
    @State private var image: UIImage?
    @State private var imageBase64 = ""
    @State private var activity: Activity<DesignActivityAttributes>?
    @State private var updateTask: Task<Void, Never>?
    @State private var note = ""

    private var state: DesignActivityAttributes.ContentState {
        DesignActivityAttributes.ContentState(
            title: title,
            imageBase64: imageBase64
        )
    }

    private var running: Bool { activity != nil }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                topBar
                list
                bottomBar
            }
        }
        .photosPicker(isPresented: $showPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { @MainActor in await loadImage(from: item) }
        }
        .onChange(of: state) { _, newState in
            guard running else { return }
            scheduleUpdate(for: newState)
        }
    }

    // MARK: - 背景（有图时是同一张图的模糊版）

    @ViewBuilder
    private var background: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: 40)
                .overlay(Palette.canvas.opacity(0.58))
                .clipped()
                .ignoresSafeArea()
        } else {
            Palette.canvas.ignoresSafeArea()
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
                    Label(image == nil ? "选择封面" : "更换封面", systemImage: "photo")
                }

                if image != nil {
                    Button(role: .destructive) {
                        clearImage()
                    } label: {
                        Label("移除封面", systemImage: "trash")
                    }
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
                coverTile
                coverHint
                titleRow
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .frame(maxHeight: .infinity)
    }

    /// 封面：一整块正方形，有图时被图片铺满，点它就能换图。
    private var coverTile: some View {
        Button {
            showPicker = true
        } label: {
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Palette.chip

                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 28, weight: .light))
                        Text("选择封面")
                            .font(.footnote)
                    }
                    .foregroundStyle(Palette.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var coverHint: some View {
        Text(image == nil ? "未选择封面时只显示一行文字" : "点击图片可更换封面")
            .font(.footnote)
            .foregroundStyle(Palette.caption)
            .padding(.top, 8)
    }

    private var titleRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField("一行文字", text: $title)
                .font(.body)
                .foregroundStyle(Palette.ink)
            Text("实时活动只显示这一行，太长会滚动")
                .font(.footnote)
                .foregroundStyle(Palette.caption)
        }
        .padding(.vertical, 16)
    }

    // MARK: - 底栏（只有启动 / 停止）

    private var bottomBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !note.isEmpty {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(Palette.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                barButton("启动实时活动", filled: true, enabled: !running) {
                    start()
                }
                barButton("停止", filled: false, enabled: running) {
                    stop()
                }
            }
        }
        .padding(8)
        .background {
            if image == nil {
                Palette.canvas
            } else {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
        .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: -4)
    }

    private func barButton(
        _ label: String,
        filled: Bool,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
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
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
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
        note = running ? "封面已同步到实时活动" : "封面已就绪（\(max(1, thumbnail.count / 1024)) KB）"
    }

    private func clearImage() {
        image = nil
        imageBase64 = ""
        photoItem = nil
        note = running ? "封面已移除" : "已移除封面"
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
        guard !running else { return }

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

    private func stop() {
        guard let activity else { return }

        Task { @MainActor in
            await activity.end(nil, dismissalPolicy: .immediate)
            updateTask?.cancel()
            self.activity = nil
            note = "已停止"
        }
    }

    /// 活动运行中改文字或换图，自动同步，不需要额外的“更新”按钮。
    private func scheduleUpdate(for content: DesignActivityAttributes.ContentState) {
        updateTask?.cancel()
        updateTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled, let activity else { return }
            await activity.update(ActivityContent(state: content, staleDate: nil))
        }
    }
}
