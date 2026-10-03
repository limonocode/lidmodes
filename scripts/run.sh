#!/usr/bin/env bash
# Build and launch LidModes menubar
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
chmod +x "$ROOT/bin/lidmodes-pmset" "$ROOT/scripts/install-nopasswd.sh" "$ROOT/scripts/uninstall-nopasswd.sh" 2>/dev/null || true
swift build -c release
BIN="$ROOT/.build/release/LidModes"
pkill -x LidModes 2>/dev/null || true
pkill -x MacTraySleep 2>/dev/null || true
sleep 0.2
export LIDMODES_ROOT="$ROOT"
# Ad-hoc signature so Keychain access control can prompt on Apple Silicon.
if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "$BIN" || true
fi
nohup env LIDMODES_ROOT="$ROOT" "$BIN" >/tmp/lidmodes.log 2>&1 &
echo "OK: LidModes pid $! · log /tmp/lidmodes.log · LIDMODES_ROOT=$ROOT"
echo "Menu bar · lid-closed asks each time until you agree to passwordless sudo"
