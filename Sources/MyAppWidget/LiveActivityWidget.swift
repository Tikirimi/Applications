import ActivityKit
import SwiftUI
import WidgetKit

struct LockScreenView: View {
    let context: ActivityViewContext<DesignActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: context.state.symbol)
                .font(.title2)
                .foregroundStyle(Color(hex: context.state.themeHex))

            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.title)
                    .font(.headline)
                    .lineLimit(1)
                if !context.state.subtitle.isEmpty {
                    Text(context.state.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if context.state.showProgress {
                Text("\(Int((context.state.progress * 100).rounded()))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
    }
}

struct DesignActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DesignActivityAttributes.self) { context in
            VStack(spacing: 10) {
                LockScreenView(context: context)

                if context.state.showProgress {
                    ProgressView(value: context.state.progress)
                        .tint(Color(hex: context.state.themeHex))
                        .padding(.horizontal, 14)
                        .padding(.bottom, 12)
                }
            }
            .activityBackgroundTint(Color(hex: context.state.themeHex).opacity(0.18))
            .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.symbol)
                        .font(.title3)
                        .foregroundStyle(Color(hex: context.state.themeHex))
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
                            .tint(Color(hex: context.state.themeHex))
                            .padding(.horizontal, 4)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.symbol)
                    .foregroundStyle(Color(hex: context.state.themeHex))
            } compactTrailing: {
                if context.state.showProgress {
                    Text("\(Int((context.state.progress * 100).rounded()))%")
                        .font(.caption2.monospacedDigit())
                } else {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(Color(hex: context.state.themeHex))
                }
            } minimal: {
                Image(systemName: context.state.symbol)
                    .foregroundStyle(Color(hex: context.state.themeHex))
            }
            .keylineTint(Color(hex: context.state.themeHex))
        }
    }
}

@main
struct MyAppWidgetBundle: WidgetBundle {
    var body: some Widget {
        DesignActivityWidget()
    }
}
