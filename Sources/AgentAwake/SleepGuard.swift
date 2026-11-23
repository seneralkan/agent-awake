import Foundation

/// Polls for agents and keeps `disablesleep` on while any are working.
@MainActor
final class SleepGuard: ObservableObject {
    static let shared = SleepGuard()

    private let defaults = UserDefaults.standard
    /// Keep sleep disabled this long after the last agent stops, so a quick follow-up prompt doesn't flip the setting.
    private let grace: TimeInterval = 60
    static let batteryFloorOptions = [10, 20, 30]

    @Published var enabled: Bool {
        didSet { defaults.set(enabled, forKey: "enabled"); tick() }
    }
    @Published var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: "notifications")
            if notificationsEnabled { Notifier.requestPermission() }
        }
    }
    /// On battery below this percentage, sleep is allowed again so a closed laptop in a bag doesn't drain flat.
    @Published var batteryFloor: Int {
        didSet { defaults.set(batteryFloor, forKey: "batteryFloor"); tick() }
    }
    @Published private(set) var batteryPercent = 100
    @Published private(set) var onBattery = false
    @Published var language: Language {
        didSet { defaults.set(language.rawValue, forKey: "language") }
    }
    /// Running agent processes by name.
    @Published private(set) var agents: [String: Int] = [:]
    /// Claude Code sessions working on a prompt right now (only meaningful when hooks are installed).
    @Published private(set) var claudeWorking = 0
    @Published private(set) var hooksInstalled = false
    @Published private(set) var sleepDisabled = false
    @Published private(set) var hasPermission = false
    @Published private(set) var batteryBlocked = false
    @Published private(set) var lastError: GuardError?

    var processNames: Set<String> {
        Set(defaults.stringArray(forKey: "processNames") ?? ["claude", "codex", "gemini", "aider", "opencode"])
    }

    /// True only when this app turned sleep off, so a manual `pmset disablesleep 1` is never undone by us.
    /// Persisted so a crash while sleep is disabled gets cleaned up on the next launch.
    private var ownsSetting: Bool {
        get { defaults.bool(forKey: "ownsSetting") }
        set { defaults.set(newValue, forKey: "ownsSetting") }
    }
    private var lastActive: Date?
    private var timer: Timer?

    private init() {
        enabled = defaults.object(forKey: "enabled") as? Bool ?? true
        notificationsEnabled = defaults.object(forKey: "notifications") as? Bool ?? true
        batteryFloor = defaults.object(forKey: "batteryFloor") as? Int ?? 20
        language = defaults.string(forKey: "language").flatMap(Language.init(rawValue:)) ?? .systemDefault
        hasPermission = Pmset.hasPermission()
        if notificationsEnabled { Notifier.requestPermission() }
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task { @MainActor in SleepGuard.shared.tick() }
        }
    }

    func tick() {
        let now = Date()
        agents = ProcessScanner.count(names: processNames)
        hooksInstalled = HookBridge.isInstalled()

        // With hooks, an open-but-idle Claude Code session doesn't count; only one working on a prompt does.
        var active = agents
        if agents["claude"] == nil {
            HookBridge.clearAll()
            claudeWorking = 0
        } else if hooksInstalled {
            claudeWorking = HookBridge.workingSessions()
            if claudeWorking == 0 { active["claude"] = nil }
        }
        if !active.isEmpty { lastActive = now }

        let battery = Battery.status()
        batteryPercent = battery.percent
        onBattery = battery.onBattery
        batteryBlocked = battery.onBattery && battery.percent < batteryFloor
        let recentlyActive = lastActive.map { now.timeIntervalSince($0) < grace } ?? false
        apply(wantDisabled: enabled && recentlyActive && !batteryBlocked)
    }

    private func apply(wantDisabled: Bool) {
        let actual = Pmset.isSleepDisabled()
        sleepDisabled = actual
        if wantDisabled && !actual {
            if set(true) { notify(.notifyBlocked) }
        } else if !wantDisabled && actual && ownsSetting {
            if set(false) { notify(batteryBlocked ? .notifyBattery : .notifyRestored) }
        }
    }

    @discardableResult
    private func set(_ disabled: Bool) -> Bool {
        if Pmset.setSleepDisabled(disabled) {
            ownsSetting = disabled
            sleepDisabled = disabled
            lastError = nil
            return true
        }
        hasPermission = Pmset.hasPermission()
        lastError = hasPermission ? .pmsetFailed : .permissionNeeded
        return false
    }

    private func notify(_ key: L10nKey) {
        if notificationsEnabled { Notifier.post(language.t(key)) }
    }

    /// Called on quit: give sleep back if we took it.
    func restore() {
        if ownsSetting && Pmset.isSleepDisabled() { set(false) }
    }

    func installPermission() {
        lastError = Pmset.installPermission().map(GuardError.installFailed)
        hasPermission = Pmset.hasPermission()
        tick()
    }

    func installHooks() {
        lastError = HookBridge.install().map(GuardError.installFailed)
        tick()
    }
}

enum GuardError: Equatable {
    case permissionNeeded, pmsetFailed
    /// Message from the macOS admin dialog or the file system (already localized by the system).
    case installFailed(String)
}
