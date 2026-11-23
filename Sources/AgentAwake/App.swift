import AppKit
import SwiftUI

@main
struct AgentAwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        // CLI mode for uninstallers: `AgentAwake --uninstall-hooks` removes the Claude Code hooks and exits.
        if CommandLine.arguments.contains("--uninstall-hooks") {
            if let error = HookBridge.uninstall() {
                FileHandle.standardError.write(Data("AgentAwake: \(error)\n".utf8))
                exit(1)
            }
            print("AgentAwake: Claude Code hooks removed")
            exit(0)
        }
    }

    var body: some Scene {
        // The menu bar item and panel are owned by StatusController (see AppDelegate).
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusController: StatusController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // `AgentAwake --render-screenshot <dir>`: renders the panel off-screen in every language
        // (for README screenshots and visual checks without screen-recording permission), then quits.
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--render-screenshot"), i + 1 < args.count {
            renderScreenshots(to: URL(fileURLWithPath: args[i + 1]))
            exit(0)
        }
        statusController = StatusController(guardian: SleepGuard.shared)
    }

    private func renderScreenshots(to dir: URL) {
        let guardian = SleepGuard.shared
        let original = guardian.language
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for lang in Language.allCases {
            guardian.language = lang
            let view = NSHostingView(rootView: PanelView(guardian: guardian))
            view.frame.size = view.fittingSize
            let window = NSWindow(contentRect: view.frame, styleMask: .borderless, backing: .buffered, defer: false)
            window.contentView = view
            view.layoutSubtreeIfNeeded()
            guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { continue }
            view.cacheDisplay(in: view.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: dir.appendingPathComponent("panel-\(lang.rawValue).png"))
        }
        guardian.language = original
    }

    func applicationWillTerminate(_ notification: Notification) {
        SleepGuard.shared.restore()
    }
}
