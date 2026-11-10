import ActivityKit
import SwiftUI
import WidgetKit

struct LockScreenView: View {
    let context: ActivityViewContext<DesignActivityAttributes>

    private var percent: String {
        "\(Int((context.state.progress * 100).rounded()))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: context.state.symbol)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.primary)

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
                    Image(systemName: context.state.symbol)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.primary)
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
                Image(systemName: context.state.symbol)
                    .foregroundStyle(.primary)
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
                Image(systemName: context.state.symbol)
                    .foregroundStyle(.primary)
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
