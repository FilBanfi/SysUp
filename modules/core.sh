#!/usr/bin/env bash
set -euo pipefail

# ===== COLORS =====
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

VERSION="0.4.0"
MODULE_NAME="CORE"
DEVELOPER="FilBanfi"

# ===== HEADER =====
echo -e "${YELLOW}======================================"
echo -e "      $MODULE_NAME MODULE v$VERSION"
echo -e "           by $DEVELOPER"
echo -e "======================================${RESET}"

echo -e "${YELLOW}[$MODULE_NAME] Starting update...${RESET}"
echo ""

# ===== SETUP =====
SYSUP_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW="https://raw.githubusercontent.com/filbanfi/sysup/${SYSUP_REF:-main}"

# plugin.conf is deliberately absent: it belongs to the user.
CORE_FILES="sysup.sh sysup-install.sh sysup-remove.sh sysup-uninstall.sh sysup-help.sh lib/common.sh plugin.conf.example"

fetch() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout 10 --max-time 120 --retry 2 "$1" -o "$2"
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=15 --tries=2 "$1" -O "$2"
    else
        return 127
    fi
}

first_line_ok() {
    local first=""
    IFS= read -r first < "$1" || true
    [[ "$first" == \#* ]]
}

# ===== COMMANDS =====
n_ok=0; n_fail=0

for rel in $CORE_FILES; do
    dest="$SYSUP_HOME/$rel"
    tmp="$(mktemp)"

    if fetch "$RAW/$rel" "$tmp" && first_line_ok "$tmp"; then
        mkdir -p "$(dirname "$dest")"
        # mv, not cp: bash reads a running script from an open fd, so replacing
        # the directory entry keeps the old inode alive until it exits.
        mv "$tmp" "$dest"
        case "$rel" in *.sh) chmod +x "$dest" ;; esac
        n_ok=$((n_ok+1))
    else
        rm -f "$tmp"
        echo -e "${RED}[$MODULE_NAME] not updated: $rel${RESET}" >&2
        n_fail=$((n_fail+1))
    fi
done

echo "[$MODULE_NAME] core: $n_ok updated, $n_fail failed"

# ===== END =====

echo ""
if (( n_fail > 0 )); then
    echo -e "${RED}[$MODULE_NAME] Update completed with errors${RESET}"
else
    echo -e "${GREEN}[$MODULE_NAME] Update completed${RESET}"
fi

echo -e "${YELLOW}======================================${RESET}"
echo ""

# A temporarily unreachable mirror must not block system updates.
exit 0