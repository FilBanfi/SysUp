#!/usr/bin/env bash
set -euo pipefail

# ===== COLORS =====
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

VERSION="1.0.0"
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
# Modulo autonomo: non usa lib/common.sh, si porta le sue funzioni.
# I moduli stanno in modules/, quindi la root di sysup è un livello sopra.
SYSUP_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW="https://raw.githubusercontent.com/filbanfi/sysup/${SYSUP_REF:-main}"

# File del core da sincronizzare. plugin.conf NON è in lista: è dell'utente.
CORE_FILES="sysup.sh sysup-install.sh sysup-remove.sh sysup-uninstall.sh lib/common.sh plugin.conf.example"

fetch() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout 10 --max-time 120 --retry 2 "$1" -o "$2"
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=15 --tries=2 "$1" -O "$2"
    else
        return 127
    fi
}

# Sanity check: la prima riga deve iniziare per '#'. Intercetta HTML di errore.
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
        # mv e non cp: bash legge lo script da un fd già aperto, mv sostituisce
        # il nome ma il vecchio inode resta vivo fino alla chiusura. Quindi
        # aggiornare un file in esecuzione (anche sysup.sh) non lo corrompe.
        mv "$tmp" "$dest"
        case "$rel" in *.sh) chmod +x "$dest" ;; esac
        n_ok=$((n_ok+1))
    else
        rm -f "$tmp"
        echo -e "${RED}[$MODULE_NAME] non aggiornato: $rel${RESET}" >&2
        n_fail=$((n_fail+1))
    fi
done

echo "[$MODULE_NAME] core: $n_ok aggiornati, $n_fail falliti"

# ===== END =====

echo ""
if (( n_fail > 0 )); then
    echo -e "${RED}[$MODULE_NAME] Update completed with errors${RESET}"
else
    echo -e "${GREEN}[$MODULE_NAME] Update completed${RESET}"
fi

echo -e "${YELLOW}======================================${RESET}"
echo ""

# Un mirror momentaneamente giù non deve bloccare gli aggiornamenti di sistema:
# usciamo comunque a 0, il riepilogo sopra dice già com'è andata.
exit 0