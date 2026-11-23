import AppKit
import Combine
import SwiftUI

/// Menu bar item + a borderless panel that always matches the SwiftUI content's size.
///
/// Replaces `MenuBarExtra(.window)`, whose window doesn't shrink when content disappears
/// (e.g. the setup card after setup), leaving an empty translucent frame around the panel.
@MainActor
final class StatusController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let host: NSHostingController<PanelView>
    private let panel: Panel
    private var outsideClickMonitor: Any?
    private var sizeObservation: NSKeyValueObservation?
    private var iconSubscription: AnyCancellable?

    init(guardian: SleepGuard) {
        host = NSHostingController(rootView: PanelView(guardian: guardian))
        host.sizingOptions = [.preferredContentSize]
        panel = Panel(contentViewController: host)
        super.init()

        if let button = item.button {
            button.target = self
            button.action = #selector(toggle)
        }
        iconSubscription = guardian.$sleepDisabled.removeDuplicates().sink { [weak self] awake in
            self?.item.button?.image = awake ? MenuBarIcon.awake : MenuBarIcon.idle
        }
        sizeObservation = host.observe(\.preferredContentSize) { [weak self] _, _ in
            Task { @MainActor in self?.reposition() }
        }
    }

    @objc private func toggle() {
        panel.isVisible ? close() : open()
    }

    private func open() {
        reposition()
        panel.makeKeyAndOrderFront(nil)
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.close() }
        }
    }

    private func close() {
        panel.orderOut(nil)
        if let monitor = outsideClickMonitor { NSEvent.removeMonitor(monitor) }
        outsideClickMonitor = nil
    }

    /// Sizes the panel to its content and hangs it under the menu bar icon, kept on screen.
    private func reposition() {
        guard let buttonWindow = item.button?.window, let screen = buttonWindow.screen ?? NSScreen.main else { return }
        let size = host.view.fittingSize
        let anchor = buttonWindow.frame
        let visible = screen.visibleFrame
        var x = anchor.midX - size.width / 2
        x = min(max(x, visible.minX + 8), visible.maxX - size.width - 8)
        let y = anchor.minY - size.height - 6
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
        panel.invalidateShadow()
    }
}

/// Borderless, transparent panel that can still take keyboard focus (for the language menu and ⌘Q).
private final class Panel: NSPanel {
    init(contentViewController: NSViewController) {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        self.contentViewController = contentViewController
        isFloatingPanel = true
        level = .statusBar
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }
}
