#!/usr/bin/env bash
# Install path-pinned lidmodes-pmset + NOPASSWD sudoers for $USER only.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/bin/lidmodes-pmset"
DEST="/usr/local/libexec/lidmodes-pmset"
SUDOERS="/etc/sudoers.d/lidmodes"
USER_NAME="$(id -un)"

if [[ ! -f "$SRC" ]]; then
  echo "ERR: missing $SRC" >&2
  exit 1
fi

echo "Installing LidModes pmset helper for user: $USER_NAME"
sudo install -d /usr/local/libexec
sudo install -m 755 -o root -g wheel "$SRC" "$DEST"

TMP="$(mktemp)"
cat >"$TMP" <<EOF
# LidModes — NOPASSWD only this binary (full path, no wildcards)
$USER_NAME ALL=(root) NOPASSWD: $DEST
EOF

if ! visudo -cf "$TMP" >/dev/null; then
  echo "ERR: sudoers syntax check failed" >&2
  rm -f "$TMP"
  exit 1
fi

sudo install -m 440 -o root -g wheel "$TMP" "$SUDOERS"
rm -f "$TMP"

if ! sudo -n "$DEST" status >/dev/null; then
  echo "ERR: sudo -n $DEST status failed after install" >&2
  exit 1
fi

echo "OK: installed $DEST"
echo "OK: sudoers $SUDOERS"
echo "Test: sudo -n $DEST status"
