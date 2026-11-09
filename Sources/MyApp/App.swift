import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.gen3")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Hello, iOS!")
                .font(.title2.weight(.semibold))
            Text("Version \(version)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospaced()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
