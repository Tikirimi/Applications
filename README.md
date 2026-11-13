# Live Activity Designer

一个 SwiftUI iOS 示例工程：在 App 里**自己设计实时活动（Live Activity）**，通过 ActivityKit（系统级 API）把它显示在锁屏和灵动岛上。

构建全程不需要签名和证书，由 GitHub Actions 自动产出**未签名 IPA**。

## 功能

- 启动前先过 **Face ID**（失败可用设备密码），冷启动才验证
- 只有一行文字，可选配一张封面图
- 封面是一整块**正方形**，图片自适应填满；同一张图模糊后铺满整屏当背景
- 从相册选一张图，自动压成缩略图，锁屏和灵动岛（展开 / 紧凑 / 最小）都会显示
- 灵动岛左右两侧：**左侧图片，右侧文字**；文字放不下会来回滚动，展开态只占最短高度
- 有图、无图是两套排版：有图时左图右文，无图时只有一行文字、没有图标也没有进度条
- 底部只有两个按钮：**启动实时活动**（`Activity.request`）和**停止**（`Activity.end`）
- 活动运行中改文字或换图会自动同步（`Activity.update`），不用额外再点一次

## 设计

- **只用黑白灰**：文字、按钮、药丸标签都是灰阶，没有任何彩色
- **底色**：浅色 `#F2F4ED`（微暖的米白），深色 `#141414`（近黑的深灰），内容直接铺在底色上
- **排版参考 PocketServer**：顶部面包屑药丸 + 圆形菜单按钮，中间是 64pt 缩略图配两行文字的列表，底部一条带阴影的操作栏
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

1. 打开 App，直接改列表里的那一行文字，点「封面图」那一行选一张图（不选就只有文字）；
2. 点「启动实时活动」，锁屏下拉或长按灵动岛就能看到；
3. 运行中继续改文字或换图，会停顿约半秒自动同步到锁屏，不用再点按钮；
4. 点「停止」收起。

图片说明：实时活动的状态有 **4KB 上限**，所以选中的照片会被缩到很小的缩略图（≤1600 字节，最多 112px），足够锁屏和灵动岛显示，请不要指望它是高清大图。

注意：实时活动需要 **iOS 16.1+**（本工程部署目标 17.0），灵动岛需要 iPhone 14 Pro 及以上；若系统关闭了实时活动，请到 设置 → 通知 → 实时活动 打开。

## 自定义

- 改显示名 / Bundle ID：编辑 `project.yml` 里两个 target 的 `PRODUCT_BUNDLE_IDENTIFIER`；
- 改版本号：编辑 `Info.plist` 的 `CFBundleShortVersionString` 与 `CFBundleVersion`；
- 改实时活动数据结构：`Shared/DesignActivityAttributes.swift`（App 与 Widget 共用，改一处两边生效）；
- 改外观：`Sources/MyAppWidget/LiveActivityWidget.swift`（锁屏 + 灵动岛），设计器界面在 `Sources/MyApp/App.swift`。
