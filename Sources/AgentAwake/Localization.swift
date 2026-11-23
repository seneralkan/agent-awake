import SwiftUI

/// English, Turkish, and the most spoken languages worldwide (Mandarin, Hindi, Spanish, Arabic).
enum Language: String, CaseIterable, Identifiable {
    case en, tr, zh, hi, es, ar

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .en: "English"
        case .tr: "Türkçe"
        case .zh: "中文"
        case .hi: "हिन्दी"
        case .es: "Español"
        case .ar: "العربية"
        }
    }

    var layoutDirection: LayoutDirection { self == .ar ? .rightToLeft : .leftToRight }

    /// First supported language from the user's macOS preferences, else English.
    static var systemDefault: Language {
        for id in Locale.preferredLanguages {
            if let lang = Language(rawValue: String(id.prefix(2))) { return lang }
        }
        return .en
    }

    /// Missing keys fall back to English.
    func t(_ key: L10nKey) -> String { Self.strings[self]?[key] ?? Self.strings[.en]![key]! }

    func t(_ key: L10nKey, _ n: Int) -> String { String(format: t(key), n) }

    private static let strings: [Language: [L10nKey: String]] = [
        .en: [
            .heroWorking: "Agents at work",
            .heroWorkingSub: "Sleep blocked · safe to close the lid",
            .heroWaiting: "Agents waiting",
            .heroWaitingSub: "Nothing running · sleep allowed",
            .heroIdle: "All quiet",
            .heroIdleSub: "No agents · sleep works normally",
            .heroPaused: "Paused",
            .heroPausedSub: "Auto-block is off",
            .batteryLow: "Low battery",
            .heroBatterySub: "Sleep allowed to protect the battery",
            .agentsSection: "Agents",
            .noAgents: "no agents running",
            .openCount: "%d open",
            .workingCount: "%d working",
            .runningCount: "%d running",
            .setupSection: "Setup",
            .stepPermission: "Allow sleep control",
            .stepPermissionSub: "One password prompt, limited to pmset",
            .stepHooks: "Claude Code hooks",
            .stepHooksSub: "Tell working sessions from idle ones",
            .setupButton: "Set up",
            .settingsSection: "Settings",
            .toggle: "Block sleep while agents work",
            .batteryFloor: "Battery floor",
            .notifications: "Notifications",
            .launchAtLogin: "Launch at login",
            .language: "Language",
            .quit: "Quit",
            .permissionNeeded: "Permission required",
            .pmsetFailed: "Couldn't run pmset",
            .notifyBlocked: "Agents are working — sleep blocked",
            .notifyRestored: "Agents finished — sleep is back on",
            .notifyBattery: "Low battery — sleep re-enabled",
        ],
        .tr: [
            .heroWorking: "Agent'lar çalışıyor",
            .heroWorkingSub: "Uyku engelli · kapağı kapatabilirsin",
            .heroWaiting: "Agent'lar bekliyor",
            .heroWaitingSub: "Çalışan iş yok · uyku serbest",
            .heroIdle: "Her şey sakin",
            .heroIdleSub: "Agent yok · uyku normal",
            .heroPaused: "Duraklatıldı",
            .heroPausedSub: "Otomatik engelleme kapalı",
            .batteryLow: "Pil düşük",
            .heroBatterySub: "Pili korumak için uyku serbest",
            .agentsSection: "Agent'lar",
            .noAgents: "çalışan agent yok",
            .openCount: "%d açık",
            .workingCount: "%d çalışıyor",
            .runningCount: "%d aktif",
            .setupSection: "Kurulum",
            .stepPermission: "Uyku kontrolüne izin ver",
            .stepPermissionSub: "Tek seferlik şifre, sadece pmset için",
            .stepHooks: "Claude Code hook'ları",
            .stepHooksSub: "Çalışan ve boşta oturumları ayırt eder",
            .setupButton: "Kur",
            .settingsSection: "Ayarlar",
            .toggle: "Agent çalışırken uykuyu engelle",
            .batteryFloor: "Pil alt sınırı",
            .notifications: "Bildirimler",
            .launchAtLogin: "Girişte başlat",
            .language: "Dil",
            .quit: "Çık",
            .permissionNeeded: "Yetki gerekli",
            .pmsetFailed: "pmset çalıştırılamadı",
            .notifyBlocked: "Agent'lar çalışıyor — uyku engellendi",
            .notifyRestored: "Agent'lar bitti — uyku tekrar açık",
            .notifyBattery: "Pil düşük — uyku tekrar açıldı",
        ],
        .zh: [
            .heroWorking: "代理正在工作",
            .heroWorkingSub: "已阻止睡眠 · 可放心合上盖子",
            .heroWaiting: "代理等待中",
            .heroWaitingSub: "无任务运行 · 允许睡眠",
            .heroIdle: "一切安静",
            .heroIdleSub: "无代理 · 正常睡眠",
            .heroPaused: "已暂停",
            .heroPausedSub: "自动阻止已关闭",
            .batteryLow: "电量低",
            .heroBatterySub: "为保护电池已允许睡眠",
            .agentsSection: "代理",
            .noAgents: "没有运行中的代理",
            .openCount: "%d 个打开",
            .workingCount: "%d 个工作中",
            .runningCount: "%d 个运行中",
            .setupSection: "设置向导",
            .stepPermission: "允许控制睡眠",
            .stepPermissionSub: "仅需输入一次密码，仅限 pmset",
            .stepHooks: "Claude Code 钩子",
            .stepHooksSub: "区分工作中与空闲的会话",
            .setupButton: "设置",
            .settingsSection: "设置",
            .toggle: "代理工作时阻止睡眠",
            .batteryFloor: "电量下限",
            .notifications: "通知",
            .launchAtLogin: "登录时启动",
            .language: "语言",
            .quit: "退出",
            .permissionNeeded: "需要授权",
            .pmsetFailed: "无法运行 pmset",
            .notifyBlocked: "代理正在工作 — 已阻止睡眠",
            .notifyRestored: "代理已完成 — 睡眠已恢复",
            .notifyBattery: "电量低 — 已恢复睡眠",
        ],
        .hi: [
            .heroWorking: "एजेंट काम कर रहे हैं",
            .heroWorkingSub: "स्लीप रोकी गई · ढक्कन बंद कर सकते हैं",
            .heroWaiting: "एजेंट प्रतीक्षा में",
            .heroWaitingSub: "कुछ नहीं चल रहा · स्लीप की अनुमति",
            .heroIdle: "सब शांत है",
            .heroIdleSub: "कोई एजेंट नहीं · स्लीप सामान्य",
            .heroPaused: "रोका गया",
            .heroPausedSub: "ऑटो-ब्लॉक बंद है",
            .batteryLow: "बैटरी कम",
            .heroBatterySub: "बैटरी बचाने के लिए स्लीप की अनुमति",
            .agentsSection: "एजेंट",
            .noAgents: "कोई एजेंट नहीं चल रहा",
            .openCount: "%d खुले",
            .workingCount: "%d काम कर रहे",
            .runningCount: "%d चल रहे",
            .setupSection: "सेटअप",
            .stepPermission: "स्लीप नियंत्रण की अनुमति दें",
            .stepPermissionSub: "केवल एक बार पासवर्ड, सिर्फ़ pmset के लिए",
            .stepHooks: "Claude Code हुक",
            .stepHooksSub: "काम कर रहे और निष्क्रिय सत्र अलग पहचानें",
            .setupButton: "सेट करें",
            .settingsSection: "सेटिंग्स",
            .toggle: "एजेंट काम करते समय स्लीप रोकें",
            .batteryFloor: "बैटरी सीमा",
            .notifications: "सूचनाएँ",
            .launchAtLogin: "लॉग इन पर शुरू करें",
            .language: "भाषा",
            .quit: "बंद करें",
            .permissionNeeded: "अनुमति आवश्यक",
            .pmsetFailed: "pmset नहीं चल सका",
            .notifyBlocked: "एजेंट काम कर रहे हैं — स्लीप रोकी गई",
            .notifyRestored: "एजेंट का काम पूरा — स्लीप फिर चालू",
            .notifyBattery: "बैटरी कम — स्लीप फिर चालू",
        ],
        .es: [
            .heroWorking: "Agentes trabajando",
            .heroWorkingSub: "Reposo bloqueado · puedes cerrar la tapa",
            .heroWaiting: "Agentes en espera",
            .heroWaitingSub: "Nada en marcha · reposo permitido",
            .heroIdle: "Todo tranquilo",
            .heroIdleSub: "Sin agentes · reposo normal",
            .heroPaused: "En pausa",
            .heroPausedSub: "Bloqueo automático desactivado",
            .batteryLow: "Batería baja",
            .heroBatterySub: "Reposo permitido para proteger la batería",
            .agentsSection: "Agentes",
            .noAgents: "no hay agentes en ejecución",
            .openCount: "%d abiertos",
            .workingCount: "%d trabajando",
            .runningCount: "%d en ejecución",
            .setupSection: "Configuración inicial",
            .stepPermission: "Permitir control del reposo",
            .stepPermissionSub: "Una sola contraseña, solo para pmset",
            .stepHooks: "Hooks de Claude Code",
            .stepHooksSub: "Distingue sesiones activas de inactivas",
            .setupButton: "Configurar",
            .settingsSection: "Ajustes",
            .toggle: "Bloquear reposo mientras trabajan agentes",
            .batteryFloor: "Límite de batería",
            .notifications: "Notificaciones",
            .launchAtLogin: "Abrir al iniciar sesión",
            .language: "Idioma",
            .quit: "Salir",
            .permissionNeeded: "Se requiere permiso",
            .pmsetFailed: "No se pudo ejecutar pmset",
            .notifyBlocked: "Los agentes están trabajando — reposo bloqueado",
            .notifyRestored: "Los agentes terminaron — el reposo vuelve a estar activo",
            .notifyBattery: "Batería baja — reposo reactivado",
        ],
        .ar: [
            .heroWorking: "الوكلاء يعملون",
            .heroWorkingSub: "تم منع السكون · يمكنك إغلاق الغطاء",
            .heroWaiting: "الوكلاء في الانتظار",
            .heroWaitingSub: "لا شيء قيد التشغيل · السكون مسموح",
            .heroIdle: "كل شيء هادئ",
            .heroIdleSub: "لا يوجد وكلاء · السكون عادي",
            .heroPaused: "متوقف مؤقتًا",
            .heroPausedSub: "المنع التلقائي متوقف",
            .batteryLow: "البطارية منخفضة",
            .heroBatterySub: "السكون مسموح لحماية البطارية",
            .agentsSection: "الوكلاء",
            .noAgents: "لا يوجد وكلاء قيد التشغيل",
            .openCount: "%d مفتوح",
            .workingCount: "%d قيد العمل",
            .runningCount: "%d قيد التشغيل",
            .setupSection: "الإعداد",
            .stepPermission: "السماح بالتحكم في السكون",
            .stepPermissionSub: "كلمة مرور مرة واحدة، لـ pmset فقط",
            .stepHooks: "خطافات Claude Code",
            .stepHooksSub: "التمييز بين الجلسات العاملة والخاملة",
            .setupButton: "إعداد",
            .settingsSection: "الإعدادات",
            .toggle: "منع السكون أثناء عمل الوكلاء",
            .batteryFloor: "الحد الأدنى للبطارية",
            .notifications: "الإشعارات",
            .launchAtLogin: "التشغيل عند تسجيل الدخول",
            .language: "اللغة",
            .quit: "إنهاء",
            .permissionNeeded: "يلزم الإذن",
            .pmsetFailed: "تعذّر تشغيل pmset",
            .notifyBlocked: "الوكلاء يعملون — تم منع السكون",
            .notifyRestored: "انتهى الوكلاء — عاد السكون",
            .notifyBattery: "البطارية منخفضة — أُعيد تفعيل السكون",
        ],
    ]
}

enum L10nKey {
    case heroWorking, heroWorkingSub, heroWaiting, heroWaitingSub, heroIdle, heroIdleSub
    case heroPaused, heroPausedSub, batteryLow, heroBatterySub
    case agentsSection, noAgents, openCount, workingCount, runningCount
    case setupSection, stepPermission, stepPermissionSub, stepHooks, stepHooksSub, setupButton
    case settingsSection, toggle, batteryFloor, notifications, launchAtLogin, language, quit
    case permissionNeeded, pmsetFailed, notifyBlocked, notifyRestored, notifyBattery
}
