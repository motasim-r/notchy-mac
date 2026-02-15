#!/usr/bin/env bash
set -euo pipefail

PLIST_PATH="$HOME/Library/LaunchAgents/com.notchy.autocommit.plist"
launchctl bootout "gui/$(id -u)/com.notchy.autocommit" >/dev/null 2>&1 || true
rm -f "$PLIST_PATH"

echo "Removed: com.notchy.autocommit"
