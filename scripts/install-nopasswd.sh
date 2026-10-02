#!/usr/bin/env bash
# Install path-pinned lidmodes-pmset + NOPASSWD sudoers for one user.
# The sudoers draft is created with mktemp inside /etc/sudoers.d and a dot
# in the file name, so sudo ignores it until visudo accepts it. There is no
# predictable temporary path.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/bin/lidmodes-pmset"
DEST="/usr/local/libexec/lidmodes-pmset"
SUDOERS="/etc/sudoers.d/lidmodes"

if [[ "$(id -u)" -eq 0 && -z "${LIDMODES_USER:-}" ]]; then
  echo "ERR: do not sudo this script directly. Run it as your user, or set LIDMODES_USER." >&2
  exit 1
fi

USER_NAME="${LIDMODES_USER:-$(id -un)}"
if [[ ! "$USER_NAME" =~ ^[A-Za-z_][A-Za-z0-9._-]*$ ]]; then
  echo "ERR: username must be letters, digits, dot, underscore, or hyphen" >&2
  exit 1
fi

if [[ ! -f "$SRC" ]]; then
  echo "ERR: missing $SRC" >&2
  exit 1
fi

# Bash 3.2 (macOS /bin/bash) errors on "${empty[@]}" with set -u.
run_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

echo "Installing LidModes pmset helper for user: $USER_NAME"
run_root mkdir -p /etc/sudoers.d
run_root install -d /usr/local/libexec
run_root install -m 755 -o root -g wheel "$SRC" "$DEST"

# Random name containing a dot: #includedir skips it while we validate.
tmp="$(run_root mktemp /etc/sudoers.d/lidmodes.XXXXXX)"
cleanup() {
  if [[ -n "${tmp:-}" ]]; then
    run_root rm -f "$tmp" || true
  fi
}
trap cleanup EXIT

run_root tee "$tmp" >/dev/null <<EOF
# LidModes — NOPASSWD only this binary (full path, no wildcards)
$USER_NAME ALL=(root) NOPASSWD: $DEST
EOF
run_root chmod 440 "$tmp"
run_root chown root:wheel "$tmp"

if ! run_root visudo -cf "$tmp" >/dev/null; then
  echo "ERR: sudoers syntax check failed" >&2
  exit 1
fi

run_root mv "$tmp" "$SUDOERS"
tmp=""
run_root chmod 440 "$SUDOERS"
run_root chown root:wheel "$SUDOERS"

if [[ "$(id -un)" == "$USER_NAME" ]]; then
  sudo -n "$DEST" status >/dev/null
else
  # Running as root for another user: do not pass "-u" through run_root.
  /usr/bin/sudo -u "$USER_NAME" /usr/bin/sudo -n "$DEST" status >/dev/null
fi

echo "OK: installed $DEST"
echo "OK: sudoers $SUDOERS"
echo "Test: sudo -n $DEST status"
