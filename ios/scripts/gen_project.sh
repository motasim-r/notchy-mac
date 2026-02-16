#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

xcodegen generate --spec "$IOS_DIR/project.yml"

echo "Generated: $IOS_DIR/NotchyTeleprompterIOS.xcodeproj"
