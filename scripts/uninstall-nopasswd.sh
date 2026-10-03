#!/usr/bin/env bash
# Remove LidModes NOPASSWD sudoers, the libexec helper, and the pmset snapshot.
set -euo pipefail

DEST="/usr/local/libexec/lidmodes-pmset"
SUDOERS="/etc/sudoers.d/lidmodes"
SNAPDIR="/usr/local/var/lidmodes"

run_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

if [[ -L "$SNAPDIR" || -L "$DEST" || -L "$SUDOERS" ]]; then
  echo "ERR: refusing to remove a symlink" >&2
  exit 1
fi

if [[ -x "$DEST" ]]; then
  run_root "$DEST" restore || true
fi

if [[ -f "$SUDOERS" ]]; then
  run_root rm -f "$SUDOERS"
  echo "OK: removed $SUDOERS"
else
  echo "skip: no $SUDOERS"
fi

if [[ -e "$DEST" ]]; then
  run_root rm -f "$DEST"
  echo "OK: removed $DEST"
else
  echo "skip: no $DEST"
fi

if [[ -d "$SNAPDIR" ]]; then
  run_root rm -rf "$SNAPDIR"
  echo "OK: removed $SNAPDIR"
fi

echo "OK: uninstall done"
