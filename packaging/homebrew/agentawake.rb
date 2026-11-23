# Homebrew cask. Put this in a tap repo (github.com/seneralkan/homebrew-tap, file Casks/agentawake.rb), then:
#   brew install --cask seneralkan/tap/agentawake
# Update `version` and `sha256` (printed by scripts/release.sh) on every release.
cask "agentawake" do
  version "1.0.0"
  sha256 "REPLACE_WITH_SHA256_FROM_RELEASE"

  url "https://github.com/seneralkan/agent-awake/releases/download/v#{version}/AgentAwake-#{version}.zip"
  name "AgentAwake"
  desc "Keeps your Mac awake, even with the lid closed, while AI coding agents work"
  homepage "https://github.com/seneralkan/agent-awake"

  depends_on macos: ">= :ventura"

  app "AgentAwake.app"

  uninstall early_script: {
              executable: "#{appdir}/AgentAwake.app/Contents/MacOS/AgentAwake",
              args:       ["--uninstall-hooks"],
            },
            quit:         "com.jarvis.AgentAwake",
            script:       {
              executable: "/usr/bin/pmset",
              args:       ["-a", "disablesleep", "0"],
              sudo:       true,
            },
            delete:       "/etc/sudoers.d/agentawake"

  zap trash: [
    "~/Library/Application Support/AgentAwake",
    "~/Library/Preferences/com.jarvis.AgentAwake.plist",
  ]
end
