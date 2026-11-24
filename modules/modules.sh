#!/usr/bin/env bash
set -euo pipefail

# ===== COLORS =====
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

VERSION="1.0.0"
MODULE_NAME="MODULES"
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
CONF="$SYSUP_HOME/plugin.conf"
MODS="$SYSUP_HOME/modules"
RAW="https://raw.githubusercontent.com/filbanfi/sysup/${SYSUP_REF:-main}"

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

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# ===== COMMANDS =====
# Aggiorna solo i moduli realmente presenti sul disco, abilitati o no:
# è l'elenco dei "moduli installati", non dei "moduli disponibili".
n_ok=0; n_fail=0

while IFS='=' read -r raw_path raw_flag || [[ -n "$raw_path" ]]; do
    path="$(trim "$raw_path")"
    if [[ -z "$path" || "$path" == \#* ]]; then continue; fi

    dest="$MODS/$path"
    if [[ ! -f "$dest" ]]; then continue; fi

    tmp="$(mktemp)"
    if fetch "$RAW/modules/$path" "$tmp" && first_line_ok "$tmp"; then
        mv "$tmp" "$dest"        # atomico: sicuro anche su sé stesso
        chmod +x "$dest"
        n_ok=$((n_ok+1))
    else
        rm -f "$tmp"
        echo -e "${RED}[$MODULE_NAME] non aggiornato: $path${RESET}" >&2
        n_fail=$((n_fail+1))
    fi
done < "$CONF"

echo "[$MODULE_NAME] moduli: $n_ok aggiornati, $n_fail falliti"

# ===== END =====

echo ""
if (( n_fail > 0 )); then
    echo -e "${RED}[$MODULE_NAME] Update completed with errors${RESET}"
else
    echo -e "${GREEN}[$MODULE_NAME] Update completed${RESET}"
fi

echo -e "${YELLOW}======================================${RESET}"
echo ""

exit 0