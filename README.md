# Live Activity Designer

一个 SwiftUI iOS 示例工程：在 App 里**自己设计实时活动（Live Activity）**，通过 ActivityKit（系统级 API）把它显示在锁屏和灵动岛上。

构建全程不需要签名和证书，由 GitHub Actions 自动产出**未签名 IPA**。

## 功能

- 只有两行文字：标题 + 副标题，可选配一张封面图
- 从相册选一张图，自动压成缩略图，锁屏和灵动岛（展开 / 紧凑 / 最小）都会显示
- 有图、无图是两套排版：有图时左图右文，无图时只有两行文字、没有图标也没有进度条
- 界面实时预览，点「启动实时活动」由 `Activity.request` 交给系统显示
- 「更新内容」随时改文案或换图（`Activity.update`），「结束活动」立即收起（`Activity.end`）

## 设计

- **只用黑白灰**：文字、按钮、进度条都是系统语义色（label / secondaryLabel / separator），没有任何彩色
- **底色**：浅色 `#F2F4ED`（微暖的米白），深色 `#141414`（近黑的深灰），内容直接铺在底色上
- **Apple 风极简**：大标题 + 发丝线分组的扁平排版，不用卡片容器，只有一颗胶囊按钮
- **浅色 / 深色自动适配**：底色等由 `Palette` 里的动态色决定，跟随系统实时切换，不用手动判断

## 结构

```
.
├── .github/workflows/build.yml        # CI：生成工程 → archive → 打包 IPA → 上传产物
├── Sources/MyApp/App.swift            # 设计器界面 + ActivityKit 控制
├── Sources/MyAppWidget/               # 实时活动 Widget 扩展（锁屏 + 灵动岛）
├── Shared/                            # App 与扩展共用的数据模型、颜色工具
├── Info.plist                         # App 配置（含 NSSupportsLiveActivities）
└── project.yml                        # XcodeGen 工程描述（主 App + Widget 扩展）
```

## 构建

推送到 `main` 会自动构建；也可以在 **Actions → Build Unsigned IPA → Run workflow** 手动触发。
产物在对应运行页面的 **Artifacts → MyApp-unsigned-ipa** 下载。

本地构建（需要 macOS + Xcode + [XcodeGen](https://github.com/yonaskolb/XcodeGen)）：

```sh
brew install xcodegen
xcodegen generate
xcodebuild archive -project MyApp.xcodeproj -scheme MyApp \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/MyApp.xcarchive \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""

mkdir -p Payload
cp -R build/MyApp.xcarchive/Products/Applications/MyApp.app Payload/
zip -r MyApp.ipa Payload
```

## 安装

产出的是**未签名** IPA：构建全程不需要任何签名或证书。

- 设备上有 TrollStore 等支持未签名包的安装器时，可直接安装；
- 否则用 AltStore、Sideloadly 等工具按设备情况装入；
- 未签名包无法上架 App Store，仅用于自测；请确认你拥有设备与账号的合法使用权。

## 使用

1. 打开 App，改标题/副标题，或点「选择照片」加一张封面，上方预览即所见即所得（没图就是纯文字版）；
2. 点「启动实时活动」，锁屏下拉或长按灵动岛就能看到（图片也在里面）；
3. 回到 App 改内容点「更新内容」，实时活动同步刷新；
4. 点「结束活动」收起。

图片说明：实时活动的状态有 **4KB 上限**，所以选中的照片会被缩到很小的缩略图（≤1600 字节，最多 112px），足够锁屏和灵动岛显示，请不要指望它是高清大图。

注意：实时活动需要 **iOS 16.1+**（本工程部署目标 17.0），灵动岛需要 iPhone 14 Pro 及以上；若系统关闭了实时活动，请到 设置 → 通知 → 实时活动 打开。

## 自定义

- 改显示名 / Bundle ID：编辑 `project.yml` 里两个 target 的 `PRODUCT_BUNDLE_IDENTIFIER`；
- 改版本号：编辑 `Info.plist` 的 `CFBundleShortVersionString` 与 `CFBundleVersion`；
- 改实时活动数据结构：`Shared/DesignActivityAttributes.swift`（App 与 Widget 共用，改一处两边生效）；
- 改外观：`Sources/MyAppWidget/LiveActivityWidget.swift`（锁屏 + 灵动岛），设计器界面在 `Sources/MyApp/App.swift`。
