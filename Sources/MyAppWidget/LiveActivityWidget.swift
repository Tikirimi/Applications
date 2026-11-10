import ActivityKit
import SwiftUI
import UIKit
import WidgetKit

/// 图片 + 图标的统一缩略图，锁屏和灵动岛共用。
struct Thumb: View {
    let base64: String
    let symbol: String
    let size: CGFloat

    private var radius: CGFloat { size * 0.28 }

    private var decoded: UIImage? {
        guard !base64.isEmpty, let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.white.opacity(0.10))

            if let image = decoded {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            } else {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .regular))
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: size, height: size)
    }
}

struct LockScreenView: View {
    let context: ActivityViewContext<DesignActivityAttributes>

    private var percent: String {
        "\(Int((context.state.progress * 100).rounded()))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Thumb(base64: context.state.imageBase64,
                      symbol: context.state.symbol,
                      size: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if !context.state.subtitle.isEmpty {
                        Text(context.state.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                if context.state.showProgress {
                    Text(percent)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            if context.state.showProgress {
                ProgressView(value: context.state.progress)
                    .tint(.primary)
            }
        }
        .padding(16)
    }
}

struct DesignActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DesignActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Thumb(base64: context.state.imageBase64,
                          symbol: context.state.symbol,
                          size: 40)
                        .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.showProgress {
                        Text("\(Int((context.state.progress * 100).rounded()))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 4)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        if !context.state.subtitle.isEmpty {
                            Text(context.state.subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.showProgress {
                        ProgressView(value: context.state.progress)
                            .tint(.primary)
                            .padding(.horizontal, 4)
                    }
                }
            } compactLeading: {
                Thumb(base64: context.state.imageBase64,
                      symbol: context.state.symbol,
                      size: 20)
            } compactTrailing: {
                if context.state.showProgress {
                    Text("\(Int((context.state.progress * 100).rounded()))%")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.primary)
                } else {
                    Circle()
                        .fill(.primary)
                        .frame(width: 6, height: 6)
                }
            } minimal: {
                Thumb(base64: context.state.imageBase64,
                      symbol: context.state.symbol,
                      size: 20)
            }
        }
    }
}

@main
struct MyAppWidgetBundle: WidgetBundle {
    var body: some Widget {
        DesignActivityWidget()
    }
}
