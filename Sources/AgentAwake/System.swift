import AppKit
import Darwin
import IOKit.ps

/// Wraps `pmset disablesleep`, which is the only switch that also keeps the Mac awake with the lid closed.
enum Pmset {
    static let sudoersPath = "/etc/sudoers.d/agentawake"

    static func isSleepDisabled() -> Bool {
        for line in run("/usr/bin/pmset", ["-g"]).output.split(separator: "\n") {
            let parts = line.split(whereSeparator: \.isWhitespace)
            if parts.first == "SleepDisabled" { return parts.last == "1" }
        }
        return false
    }

    /// Needs the sudoers rule from `installPermission()`; `-n` makes sudo fail instead of prompting.
    static func setSleepDisabled(_ disabled: Bool) -> Bool {
        run("/usr/bin/sudo", ["-n", "/usr/bin/pmset", "-a", "disablesleep", disabled ? "1" : "0"]).status == 0
    }

    static func hasPermission() -> Bool {
        run("/usr/bin/sudo", ["-n", "-l", "/usr/bin/pmset", "-a", "disablesleep", "1"]).status == 0
    }

    /// Installs a sudoers rule that allows exactly `pmset -a disablesleep 0|1` without a password.
    /// Asks for the admin password once via the standard macOS dialog. Returns an error message on failure.
    static func installPermission() -> String? {
        let rule = "\(NSUserName()) ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1\n"
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("agentawake.sudoers")
        do { try rule.write(to: tmp, atomically: true, encoding: .utf8) } catch { return error.localizedDescription }
        let cmd = "/usr/sbin/visudo -cf '\(tmp.path)' && /usr/bin/install -m 0440 -o root -g wheel '\(tmp.path)' \(sudoersPath)"
        var err: NSDictionary?
        NSAppleScript(source: "do shell script \"\(cmd)\" with administrator privileges")?.executeAndReturnError(&err)
        try? FileManager.default.removeItem(at: tmp)
        return err.map { ($0[NSAppleScript.errorMessage] as? String) ?? "sudoers install failed" }
    }

    @discardableResult
    private static func run(_ path: String, _ args: [String]) -> (status: Int32, output: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch { return (-1, "") }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (p.terminationStatus, String(decoding: data, as: UTF8.self))
    }
}

enum ProcessScanner {
    /// Counts running processes whose exact name is in `names` (case-sensitive, so the "Claude" desktop app is not counted).
    static func count(names: Set<String>) -> [String: Int] {
        let capacity = Int(proc_listallpids(nil, 0)) + 64
        var pids = [pid_t](repeating: 0, count: capacity)
        let n = Int(proc_listallpids(&pids, Int32(capacity * MemoryLayout<pid_t>.size)))
        var result: [String: Int] = [:]
        var buf = [CChar](repeating: 0, count: 256)
        for pid in pids.prefix(max(n, 0)) where pid > 0 {
            guard proc_name(pid, &buf, UInt32(buf.count)) > 0 else { continue }
            let name = String(cString: buf)
            if names.contains(name) { result[name, default: 0] += 1 }
        }
        return result
    }
}

enum Battery {
    static func status() -> (onBattery: Bool, percent: Int) {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return (false, 100) }
        for source in list {
            guard let d = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  d[kIOPSTypeKey] as? String == kIOPSInternalBatteryType else { continue }
            let cap = d[kIOPSCurrentCapacityKey] as? Int ?? 100
            let max = d[kIOPSMaxCapacityKey] as? Int ?? 100
            return (d[kIOPSPowerSourceStateKey] as? String == kIOPSBatteryPowerValue, max > 0 ? cap * 100 / max : cap)
        }
        return (false, 100)
    }
}
