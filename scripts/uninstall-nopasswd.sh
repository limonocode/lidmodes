#!/usr/bin/env bash
# Remove LidModes NOPASSWD sudoers + libexec helper. Best-effort restore pmset.
set -euo pipefail
DEST="/usr/local/libexec/lidmodes-pmset"
SUDOERS="/etc/sudoers.d/lidmodes"

if [[ -x "$DEST" ]]; then
  sudo -n "$DEST" restore 2>/dev/null || sudo "$DEST" restore 2>/dev/null || true
fi

if [[ -f "$SUDOERS" ]]; then
  sudo rm -f "$SUDOERS"
  echo "OK: removed $SUDOERS"
else
  echo "skip: no $SUDOERS"
fi

if [[ -e "$DEST" ]]; then
  sudo rm -f "$DEST"
  echo "OK: removed $DEST"
else
  echo "skip: no $DEST"
fi

echo "OK: uninstall done"
