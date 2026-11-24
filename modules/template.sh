#!/usr/bin/env bash
set -euo pipefail

# ===== COLORS =====
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

VERSION="0.1.0"
MODULE_NAME="MODULE_NAME"
DEVELOPER="FilBanfi"

# ===== HEADER =====
echo -e "${YELLOW}======================================"
echo -e "      $MODULE_NAME MODULE v$VERSION"
echo -e "           by $DEVELOPER"
echo -e "======================================${RESET}"

echo -e "${YELLOW}[$MODULE_NAME] Starting update...${RESET}"
echo ""

# ===== COMMANDS =====

# insert commands here
# example:
# sudo dnf --refresh upgrade -y

# ===== END =====

echo ""
echo -e "${GREEN}[$MODULE_NAME] Update completed${RESET}"

echo -e "${YELLOW}======================================${RESET}"
echo ""

# =============================================================================
# CONTRATTO DEL MODULO (leggilo prima di scrivere il tuo)
# 1. Script bash autonomo: nessuna dipendenza dal core, nessun source di lib/.
# 2. NON interattivo: usa -y / --noconfirm / --non-interactive.
# 3. Exit 0 = successo, exit != 0 = fallimento. Il core stampa [OK]/[FAIL] e
#    continua con il modulo successivo.
# 4. Niente blocco EXIT_CODE=$?: con set -e, se un comando fallisce lo script
#    esce subito e il messaggio "Update completed" non viene raggiunto.
# 5. I privilegi si chiedono QUI (sudo/doas), mai nel core: flatpak, pipx, brew,
#    yay e paru non vogliono girare come root.
# 6. Niente spazi nel nome del file. Il nome del modulo = il comando che aggiorna.
# 7. Se scrivi un modulo tuo, non chiamarlo come uno ufficiale: modules.sh al
#    primo sync te lo sovrascriverebbe. Usa un nome tipo my-dnf.sh.
# =============================================================================