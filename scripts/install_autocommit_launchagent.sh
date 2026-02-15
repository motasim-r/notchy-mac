#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLIST_PATH="$HOME/Library/LaunchAgents/com.notchy.autocommit.plist"
SCRIPT_PATH="$REPO_DIR/scripts/auto_git_sync.sh"

mkdir -p "$HOME/Library/LaunchAgents"
mkdir -p "$HOME/Library/Logs/Notchy"

cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.notchy.autocommit</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$SCRIPT_PATH</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>WorkingDirectory</key>
  <string>$REPO_DIR</string>
  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/Notchy/autocommit.stdout.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/Notchy/autocommit.stderr.log</string>
</dict>
</plist>
PLIST

launchctl bootout "gui/$(id -u)/com.notchy.autocommit" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"
launchctl enable "gui/$(id -u)/com.notchy.autocommit"
launchctl kickstart -k "gui/$(id -u)/com.notchy.autocommit"

echo "Installed and started: com.notchy.autocommit"
echo "Plist: $PLIST_PATH"
echo "Log: $HOME/Library/Logs/Notchy/autocommit.log"
