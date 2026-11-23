import ServiceManagement
import SwiftUI

// MARK: - Theme (night sky, amber moon, mint terminal glow — same palette as the app icon)

enum Theme {
    static let skyTop = Color(hex: 0x241A5C)
    static let skyBottom = Color(hex: 0x090B20)
    static let mint = Color(hex: 0x7CF7D0)
    static let amber = Color(hex: 0xFFC86B)
    static let moonLight = Color(hex: 0xFFE7A8)
    static let rose = Color(hex: 0xFF7A90)
    static let sky = Color(hex: 0x8AB4FF)
    static let ink = Color(hex: 0x0B1028)
    static let card = Color.white.opacity(0.055)
    static let stroke = Color.white.opacity(0.09)
    static let secondary = Color.white.opacity(0.58)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

enum HeroState { case working, waiting, idle, paused, battery }

extension SleepGuard {
    var heroState: HeroState {
        if !enabled { return .paused }
        if batteryBlocked { return .battery }
        if sleepDisabled { return .working }
        return agents.isEmpty ? .idle : .waiting
    }
}

// MARK: - Panel

struct PanelView: View {
    @ObservedObject var guardian: SleepGuard
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    private var lang: Language { guardian.language }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeroView(state: guardian.heroState, lang: lang)
            if let error = guardian.lastError { ErrorBanner(text: message(for: error)) }
            TerminalPanel(guardian: guardian)
            if !guardian.hasPermission || !guardian.hooksInstalled { SetupCard(guardian: guardian) }
            SettingsCard(guardian: guardian, launchAtLogin: $launchAtLogin)
            footer
        }
        .padding(14)
        .frame(width: 340)
        .background(NightSky(glow: guardian.heroState == .working ? Theme.mint : Theme.amber))
        .environment(\.layoutDirection, lang.layoutDirection)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: guardian.heroState)
        .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
    }

    private var footer: some View {
        HStack {
            Text("AgentAwake \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(Theme.secondary)
            Spacer()
            Button(lang.t(.quit)) { NSApp.terminate(nil) }
                .buttonStyle(GhostButton())
                .keyboardShortcut("q")
        }
        .padding(.horizontal, 4)
    }

    private func message(for error: GuardError) -> String {
        switch error {
        case .permissionNeeded: lang.t(.permissionNeeded)
        case .pmsetFailed: lang.t(.pmsetFailed)
        case .installFailed(let detail): detail
        }
    }
}

// MARK: - Background

struct NightSky: View {
    let glow: Color
    private static let stars: [(x: CGFloat, y: CGFloat, r: CGFloat, a: Double)] = [
        (0.08, 0.05, 1.2, 0.8), (0.22, 0.12, 0.8, 0.5), (0.41, 0.04, 1.0, 0.7), (0.63, 0.09, 0.7, 0.4),
        (0.9, 0.06, 1.1, 0.7), (0.78, 0.17, 0.8, 0.5), (0.13, 0.24, 0.7, 0.35), (0.55, 0.2, 0.6, 0.3),
        (0.95, 0.3, 0.7, 0.35), (0.04, 0.45, 0.8, 0.3), (0.93, 0.62, 0.7, 0.25), (0.06, 0.8, 0.7, 0.25),
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.skyTop, Theme.skyBottom], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [glow.opacity(0.22), .clear], center: UnitPoint(x: 0.15, y: 0.06), startRadius: 0, endRadius: 220)
            Canvas { ctx, size in
                for s in Self.stars {
                    let rect = CGRect(x: s.x * size.width - s.r, y: s.y * size.height - s.r, width: s.r * 2, height: s.r * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(s.a)))
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Hero

struct HeroView: View {
    let state: HeroState
    let lang: Language

    var body: some View {
        HStack(spacing: 14) {
            StatusOrb(active: state == .working, dimmed: state == .paused)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }

    private var title: String {
        switch state {
        case .working: lang.t(.heroWorking)
        case .waiting: lang.t(.heroWaiting)
        case .idle: lang.t(.heroIdle)
        case .paused: lang.t(.heroPaused)
        case .battery: lang.t(.batteryLow)
        }
    }

    private var subtitle: String {
        switch state {
        case .working: lang.t(.heroWorkingSub)
        case .waiting: lang.t(.heroWaitingSub)
        case .idle: lang.t(.heroIdleSub)
        case .paused: lang.t(.heroPausedSub)
        case .battery: lang.t(.heroBatterySub)
        }
    }
}

/// The app icon in miniature: crescent moon, plus a glowing, breathing `>_` while agents work.
struct StatusOrb: View {
    let active: Bool
    let dimmed: Bool
    @State private var breathe = false

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [(active ? Theme.mint : Theme.amber).opacity(0.3), .clear],
                                     center: .center, startRadius: 6, endRadius: 34))
                .scaleEffect(active && breathe ? 1.15 : 1)
            Circle()
                .fill(Color.white.opacity(0.06))
                .overlay(Circle().stroke(Theme.stroke))
                .frame(width: 52, height: 52)
            Moon()
                .frame(width: active ? 22 : 26, height: active ? 22 : 26)
                .offset(x: active ? 7 : 0, y: active ? -6 : 0)
            if active {
                Text(">_")
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.mint)
                    .shadow(color: Theme.mint.opacity(0.9), radius: breathe ? 7 : 2)
                    .offset(x: -8, y: 9)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 64, height: 64)
        .saturation(dimmed ? 0 : 1)
        .opacity(dimmed ? 0.6 : 1)
        .environment(\.layoutDirection, .leftToRight)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { breathe = true }
        }
    }
}

struct Moon: View {
    var body: some View {
        GeometryReader { geo in
            let d = geo.size.width
            Circle()
                .fill(LinearGradient(colors: [Theme.moonLight, Theme.amber], startPoint: .topLeading, endPoint: .bottomTrailing))
                .mask(
                    Rectangle()
                        .overlay(Circle().offset(x: -d * 0.36, y: -d * 0.26).blendMode(.destinationOut))
                        .compositingGroup()
                )
        }
    }
}

// MARK: - Live agents ("terminal")

struct TerminalPanel: View {
    @ObservedObject var guardian: SleepGuard
    @State private var cursorVisible = true

    private var lang: Language { guardian.language }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Text("~").foregroundStyle(Theme.mint)
                Text("$ agents").foregroundStyle(.white.opacity(0.85))
                Spacer()
                SectionLabel(text: lang.t(.agentsSection))
            }
            .environment(\.layoutDirection, .leftToRight)
            if guardian.agents.isEmpty {
                HStack(spacing: 4) {
                    Text("– \(lang.t(.noAgents))").font(.system(size: 12)).foregroundStyle(Theme.secondary)
                    Text("▍").foregroundStyle(Theme.mint).opacity(cursorVisible ? 1 : 0)
                }
            } else {
                ForEach(guardian.agents.keys.sorted(), id: \.self) { name in
                    row(name: name, count: guardian.agents[name] ?? 0)
                }
            }
        }
        .font(.system(size: 12, design: .monospaced))
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black.opacity(0.32)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.mint.opacity(0.14)))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { cursorVisible = false }
        }
    }

    @ViewBuilder
    private func row(name: String, count: Int) -> some View {
        let claudeTracked = name == "claude" && guardian.hooksInstalled
        let working = claudeTracked ? guardian.claudeWorking > 0 : true
        HStack(spacing: 8) {
            PulseDot(color: working ? Theme.mint : Theme.amber, pulsing: working && guardian.sleepDisabled)
            Text(name).foregroundStyle(.white)
            Spacer()
            Text(claudeTracked
                 ? "\(lang.t(.openCount, count)) · \(lang.t(.workingCount, guardian.claudeWorking))"
                 : lang.t(.runningCount, count))
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.secondary)
        }
    }
}

struct PulseDot: View {
    let color: Color
    let pulsing: Bool
    @State private var on = false

    var body: some View {
        ZStack {
            if pulsing {
                Circle().fill(color.opacity(0.35)).frame(width: 14, height: 14).scaleEffect(on ? 1 : 0.4).opacity(on ? 0 : 1)
            }
            Circle().fill(color).frame(width: 7, height: 7).shadow(color: color.opacity(0.8), radius: 3)
        }
        .frame(width: 14, height: 14)
        .onAppear {
            withAnimation(.easeOut(duration: 1.3).repeatForever(autoreverses: false)) { on = true }
        }
    }
}

// MARK: - Setup

struct SetupCard: View {
    @ObservedObject var guardian: SleepGuard
    private var lang: Language { guardian.language }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: lang.t(.setupSection))
            SetupStep(number: 1, done: guardian.hasPermission,
                      title: lang.t(.stepPermission), subtitle: lang.t(.stepPermissionSub),
                      button: lang.t(.setupButton)) { guardian.installPermission() }
            SetupStep(number: 2, done: guardian.hooksInstalled,
                      title: lang.t(.stepHooks), subtitle: lang.t(.stepHooksSub),
                      button: lang.t(.setupButton)) { guardian.installHooks() }
        }
        .card()
    }
}

struct SetupStep: View {
    let number: Int
    let done: Bool
    let title: String
    let subtitle: String
    let button: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                if done {
                    Circle().fill(Theme.mint)
                    Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.ink)
                } else {
                    Circle().stroke(Theme.amber.opacity(0.8), lineWidth: 1.5)
                    Text("\(number)").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Theme.amber)
                }
            }
            .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 12.5, weight: .medium)).foregroundStyle(done ? Theme.secondary : .white)
                Text(subtitle).font(.system(size: 10.5)).foregroundStyle(Theme.secondary)
            }
            Spacer(minLength: 4)
            if !done { Button(button, action: action).buttonStyle(PillButton()) }
        }
    }
}

// MARK: - Settings

struct SettingsCard: View {
    @ObservedObject var guardian: SleepGuard
    @Binding var launchAtLogin: Bool
    private var lang: Language { guardian.language }

    var body: some View {
        VStack(spacing: 0) {
            SettingRow(icon: "moon.zzz.fill", tint: Theme.amber, title: lang.t(.toggle)) {
                Toggle("", isOn: $guardian.enabled).mintSwitch()
            }
            RowDivider()
            SettingRow(icon: batteryIcon, tint: Theme.rose, title: lang.t(.batteryFloor),
                       detail: guardian.onBattery ? "\(guardian.batteryPercent)%" : nil) {
                PillPicker(options: SleepGuard.batteryFloorOptions, selection: $guardian.batteryFloor)
            }
            RowDivider()
            SettingRow(icon: "bell.fill", tint: Theme.sky, title: lang.t(.notifications)) {
                Toggle("", isOn: $guardian.notificationsEnabled).mintSwitch()
            }
            RowDivider()
            SettingRow(icon: "power", tint: Theme.mint, title: lang.t(.launchAtLogin)) {
                Toggle("", isOn: Binding(
                    get: { launchAtLogin },
                    set: { on in
                        try? (on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister())
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                )).mintSwitch()
            }
            RowDivider()
            SettingRow(icon: "globe", tint: Color(hex: 0xC9A7FF), title: lang.t(.language)) {
                Menu {
                    ForEach(Language.allCases) { option in
                        Button(option.nativeName) { guardian.language = option }
                    }
                } label: {
                    Text(lang.nativeName)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.stroke))
    }

    private var batteryIcon: String {
        guard guardian.onBattery else { return "battery.100.bolt" }
        switch guardian.batteryPercent {
        case ..<25: return "battery.25"
        case ..<50: return "battery.50"
        case ..<75: return "battery.75"
        default: return "battery.100"
        }
    }
}

struct SettingRow<Accessory: View>: View {
    let icon: String
    let tint: Color
    let title: String
    var detail: String? = nil
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(tint.opacity(0.16)))
            Text(title).font(.system(size: 12.5)).foregroundStyle(.white).lineLimit(2)
            if let detail {
                Text(detail).font(.system(size: 10.5, design: .monospaced)).foregroundStyle(Theme.secondary)
            }
            Spacer(minLength: 6)
            accessory()
        }
        .padding(.vertical, 7)
    }
}

struct PillPicker: View {
    let options: [Int]
    @Binding var selection: Int
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { value in
                Text("\(value)%")
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .fixedSize()
                    .foregroundStyle(value == selection ? Theme.ink : Theme.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background {
                        if value == selection {
                            Capsule().fill(Theme.mint).matchedGeometryEffect(id: "pill", in: ns)
                        }
                    }
                    .contentShape(Capsule())
                    .onTapGesture { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = value } }
            }
        }
        .padding(2)
        .background(Capsule().fill(Color.black.opacity(0.3)))
    }
}

// MARK: - Small pieces

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9.5, weight: .semibold))
            .tracking(1.1)
            .foregroundStyle(Theme.secondary)
    }
}

struct ErrorBanner: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.rose)
            Text(text).font(.system(size: 11.5)).foregroundStyle(.white)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.rose.opacity(0.14)))
    }
}

struct RowDivider: View {
    var body: some View { Rectangle().fill(Theme.stroke).frame(height: 1).padding(.leading, 34) }
}

struct PillButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(Theme.mint.opacity(configuration.isPressed ? 0.7 : 1)))
            .shadow(color: Theme.mint.opacity(0.35), radius: 6)
    }
}

struct GhostButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.5 : 0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().stroke(Theme.stroke, lineWidth: 1))
    }
}

extension View {
    func card() -> some View {
        padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.stroke))
    }

    func mintSwitch() -> some View {
        toggleStyle(.switch).tint(Theme.mint).labelsHidden().controlSize(.small)
    }
}
