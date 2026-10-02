#!/usr/bin/env bash
# Checks that can run without macOS: helper snapshot behavior, installer
# guards, and absence of a predictable sudoers temp path.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

bash -n "$ROOT/scripts/install-nopasswd.sh"
bash -n "$ROOT/scripts/uninstall-nopasswd.sh"
bash -n "$ROOT/scripts/run.sh"
sh -n "$ROOT/bin/lidmodes-pmset"

if grep -R -n --exclude 'test-security.sh' '/tmp/lidmodes-sudoers' \
  "$ROOT/Sources" "$ROOT/scripts" "$ROOT/bin"
then
  echo "ERR: predictable sudoers temp path is back" >&2
  exit 1
fi

if ! grep -q 'lidmodes.XXXXXX' "$ROOT/scripts/install-nopasswd.sh"; then
  echo "ERR: installer does not use a random sudoers temp name" >&2
  exit 1
fi

set +e
LIDMODES_USER='bad user' "$ROOT/scripts/install-nopasswd.sh" >"$TMP/bad-user.out" 2>&1
code=$?
set -e
if [[ "$code" -eq 0 ]]; then
  echo "ERR: unsafe username was accepted" >&2
  exit 1
fi
if grep -q 'sudo ' "$TMP/bad-user.out"; then
  echo "ERR: unsafe username reached sudo" >&2
  cat "$TMP/bad-user.out" >&2
  exit 1
fi

MOCK="$TMP/pmset"
LOG="$TMP/log"
VAR="$TMP/var"
cat >"$MOCK" <<EOF
#!/bin/sh
echo "\$*" >> "$LOG"
if [ "\$1" = "-g" ] && [ "\$2" = "custom" ]; then
  if [ -f "$TMP/no-battery" ]; then
    echo "AC Power:"
    echo " sleep                0"
    exit 0
  fi
  cat <<'OUT'
Battery Power:
 sleep                45
 lowpowermode         0
 tcpkeepalive         1
AC Power:
 sleep                0
OUT
  exit 0
fi
if [ "\$1" = "-g" ]; then
  echo "SleepDisabled 0"
  exit 0
fi
exit 0
EOF
chmod +x "$MOCK"

sed \
  -e "s#/usr/bin/pmset#$MOCK#g" \
  -e "s#/usr/local/var/lidmodes#$VAR#g" \
  "$ROOT/bin/lidmodes-pmset" >"$TMP/helper"
chmod +x "$TMP/helper"
: >"$LOG"

"$TMP/helper" on
grep -q '^sleep=45$' "$VAR/battery-snapshot"
grep -q '^lowpowermode=0$' "$VAR/battery-snapshot"
grep -F -q -- '-a disablesleep 1' "$LOG"
grep -F -q -- '-b sleep 0' "$LOG"

printf '%s\n' 'sleep=7' 'lowpowermode=0' 'tcpkeepalive=1' >"$VAR/battery-snapshot"
"$TMP/helper" on
grep -q '^sleep=7$' "$VAR/battery-snapshot"

"$TMP/helper" off
test ! -f "$VAR/battery-snapshot"
grep -F -q -- '-b sleep 7' "$LOG"
if grep -F -q -- 'lowpowermode 1' "$LOG"; then
  echo "ERR: helper forced lowpowermode 1" >&2
  exit 1
fi

"$TMP/helper" status >/dev/null

set +e
"$TMP/helper" nope >/dev/null 2>&1
code=$?
set -e
test "$code" -eq 2

mkdir -p "$VAR"
printf '%s\n' 'sleep=1;reboot' >"$VAR/battery-snapshot"
set +e
"$TMP/helper" restore >"$TMP/bad-snap.out" 2>&1
code=$?
set -e
test "$code" -ne 0
if grep -F -q 'reboot' "$LOG"; then
  echo "ERR: malicious snapshot value was passed to pmset" >&2
  exit 1
fi

rm -rf "$VAR"
: >"$LOG"
touch "$TMP/no-battery"
"$TMP/helper" on
test ! -f "$VAR/battery-snapshot"
grep -F -q -- '-a disablesleep 1' "$LOG"
if grep -F -q -- '-b sleep' "$LOG"; then
  echo "ERR: desktop helper changed battery sleep" >&2
  exit 1
fi

echo "OK: security checks"
