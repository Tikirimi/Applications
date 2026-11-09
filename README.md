# Test IPA Applications

一个最小的 SwiftUI iOS 示例工程，用 GitHub Actions 自动构建**未签名 IPA**，方便在测试设备上侧载验证。

## 结构

```
.
├── .github/workflows/build.yml   # CI：生成工程 → archive → 打包 IPA → 上传产物
├── Sources/MyApp/App.swift       # App 入口
├── Info.plist                    # Bundle 配置
└── project.yml                   # XcodeGen 工程描述
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

## 自定义

- 改显示名 / Bundle ID：编辑 `project.yml` 的 `options.bundleIdPrefix`，或给 `MyApp` target 设置 `PRODUCT_BUNDLE_IDENTIFIER`；
- 改版本号：编辑 `Info.plist` 的 `CFBundleShortVersionString` 与 `CFBundleVersion`；
- 改界面：编辑 `Sources/MyApp/App.swift`。
