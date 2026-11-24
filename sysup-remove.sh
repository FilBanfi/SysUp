#!/usr/bin/env bash
# Removes an installed module and its line in plugin.conf.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

MODULE="${1:-}"
if [[ -z "$MODULE" ]]; then
    err "Usage: sysup-remove <module-name>   (e.g. sysup-remove paru)"
    exit 2
fi

if [[ "$MODULE" != *.sh ]]; then MODULE="$MODULE.sh"; fi
if [[ "$MODULE" == */* || "$MODULE" == *[[:space:]]* || "$MODULE" == ".sh" ]]; then
    err "Invalid module name: $MODULE"; exit 2
fi

file="$SYSUP_MODULES/$MODULE"

if [[ -f "$file" ]]; then
    rm -f "$file"
    ok "Removed: $MODULE"
else
    warn "Module not present on disk: $MODULE"
fi

# cat instead of mv keeps the original inode and permissions.
# grep -v exits 1 when it produces no output, hence || true.
if [[ -f "$SYSUP_CONFIG" ]] && grep -q "^${MODULE}=" "$SYSUP_CONFIG"; then
    tmp="$(mktemp)"
    grep -v "^${MODULE}=" "$SYSUP_CONFIG" > "$tmp" || true
    cat "$tmp" > "$SYSUP_CONFIG"
    rm -f "$tmp"
    ok "Line removed from plugin.conf."
fi