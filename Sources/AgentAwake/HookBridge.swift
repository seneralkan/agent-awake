import Foundation

/// Tells "Claude Code is working on a prompt" apart from "a Claude Code session is just open".
///
/// Claude Code hooks call a tiny shell script that creates a marker file per session when a prompt starts
/// (and on every tool call, as a heartbeat) and deletes it when the turn ends. While any fresh marker
/// exists, Claude counts as busy.
enum HookBridge {
    static let supportDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/AgentAwake")
    static let busyDir = supportDir.appendingPathComponent("busy")
    static let hookScript = supportDir.appendingPathComponent("claude-hook.sh")
    static let claudeSettings = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/settings.json")

    /// A marker that hasn't been refreshed for this long is treated as left over from a killed session.
    static let staleAfter: TimeInterval = 3 * 60 * 60

    private static let script = """
    #!/bin/sh
    # AgentAwake hook for Claude Code. Usage: claude-hook.sh busy|idle  (hook JSON arrives on stdin)
    dir="$HOME/Library/Application Support/AgentAwake/busy"
    id=$(tr -d '\\n' | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\\([^"]*\\)".*/\\1/p')
    case "$id" in ""|*/*|.*) exit 0 ;; esac
    mkdir -p "$dir"
    case "$1" in
      busy) touch "$dir/$id" ;;
      idle) rm -f "$dir/$id" ;;
    esac
    exit 0
    """

    /// Hook events and the state each one reports.
    private static let events: [(event: String, matcher: String?, arg: String)] = [
        ("UserPromptSubmit", nil, "busy"),
        ("PreToolUse", "*", "busy"),
        ("Stop", nil, "idle"),
        ("SessionEnd", nil, "idle"),
    ]

    private static func command(_ arg: String) -> String { "'\(hookScript.path)' \(arg)" }

    static func isInstalled() -> Bool {
        guard FileManager.default.isExecutableFile(atPath: hookScript.path),
              let data = try? Data(contentsOf: claudeSettings),
              let text = String(data: data, encoding: .utf8) else { return false }
        return text.contains(hookScript.lastPathComponent)
    }

    /// Writes the hook script and merges the hook entries into ~/.claude/settings.json
    /// (after saving a backup next to it). Returns an error message on failure.
    static func install() -> String? {
        do {
            let fm = FileManager.default
            try fm.createDirectory(at: supportDir, withIntermediateDirectories: true)
            try script.write(to: hookScript, atomically: true, encoding: .utf8)
            try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: hookScript.path)

            var settings: [String: Any] = [:]
            if let data = try? Data(contentsOf: claudeSettings) {
                guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return "~/.claude/settings.json is not a JSON object"
                }
                settings = parsed
                try? fm.removeItem(at: claudeSettings.appendingPathExtension("agentawake-backup"))
                try fm.copyItem(at: claudeSettings, to: claudeSettings.appendingPathExtension("agentawake-backup"))
            } else {
                try fm.createDirectory(at: claudeSettings.deletingLastPathComponent(), withIntermediateDirectories: true)
            }

            var hooks = settings["hooks"] as? [String: Any] ?? [:]
            for (event, matcher, arg) in events {
                var entries = hooks[event] as? [[String: Any]] ?? []
                let cmd = command(arg)
                let present = entries.contains { entry in
                    (entry["hooks"] as? [[String: Any]])?.contains { $0["command"] as? String == cmd } ?? false
                }
                if present { continue }
                var entry: [String: Any] = ["hooks": [["type": "command", "command": cmd]]]
                if let matcher { entry["matcher"] = matcher }
                entries.append(entry)
                hooks[event] = entries
            }
            settings["hooks"] = hooks

            let out = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
            try out.write(to: claudeSettings, options: .atomic)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    /// Removes AgentAwake's entries from ~/.claude/settings.json (leaving everything else) and deletes the hook script.
    static func uninstall() -> String? {
        do {
            if let data = try? Data(contentsOf: claudeSettings),
               var settings = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               var hooks = settings["hooks"] as? [String: Any] {
                let ours = hookScript.lastPathComponent
                for (event, value) in hooks {
                    guard let entries = value as? [[String: Any]] else { continue }
                    let kept = entries.filter { entry in
                        !((entry["hooks"] as? [[String: Any]])?.contains { ($0["command"] as? String)?.contains(ours) == true } ?? false)
                    }
                    hooks[event] = kept.isEmpty ? nil : kept
                }
                settings["hooks"] = hooks.isEmpty ? nil : hooks
                let out = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
                try out.write(to: claudeSettings, options: .atomic)
            }
            try? FileManager.default.removeItem(at: hookScript)
            clearAll()
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    /// Number of Claude Code sessions currently working on a prompt. Deletes stale markers.
    static func workingSessions() -> Int {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: busyDir, includingPropertiesForKeys: [.contentModificationDateKey]) else { return 0 }
        var count = 0
        for file in files {
            let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            if Date().timeIntervalSince(modified) > staleAfter {
                try? fm.removeItem(at: file)
            } else {
                count += 1
            }
        }
        return count
    }

    /// Called when no `claude` process is running: any marker left is from a crashed or killed session.
    static func clearAll() {
        try? FileManager.default.removeItem(at: busyDir)
    }
}
