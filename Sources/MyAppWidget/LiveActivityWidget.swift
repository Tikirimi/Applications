import ActivityKit
import SwiftUI
import UIKit
import WidgetKit

private func decode(_ base64: String) -> UIImage? {
    guard !base64.isEmpty, let data = Data(base64Encoded: base64) else { return nil }
    return UIImage(data: data)
}

/// 锁屏：有图 → 左图右文；无图 → 只有两行文字。
struct LockScreenView: View {
    let context: ActivityViewContext<DesignActivityAttributes>

    private var image: UIImage? { decode(context.state.imageBase64) }

    var body: some View {
        Group {
            if let image {
                HStack(alignment: .center, spacing: 14) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                    texts
                }
            } else {
                texts
            }
        }
        .padding(16)
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(context.state.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if !context.state.subtitle.isEmpty {
                Text(context.state.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DesignActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DesignActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            let image = decode(context.state.imageBase64)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 34, height: 34)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding(.leading, 6)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        if !context.state.subtitle.isEmpty {
                            Text(context.state.subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            } compactLeading: {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            } compactTrailing: {
                if image == nil {
                    Circle()
                        .fill(.primary)
                        .frame(width: 6, height: 6)
                }
            } minimal: {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                } else {
                    Circle()
                        .fill(.primary)
                        .frame(width: 6, height: 6)
                }
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
