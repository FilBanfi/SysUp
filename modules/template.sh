#!/usr/bin/env bash
set -euo pipefail

# ===== COLORS =====
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

VERSION="0.4.0"
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

# MODULE CONTRACT
# - Standalone bash script, no dependency on the core.
# - Non-interactive: always pass -y / --noconfirm / --non-interactive.
# - Exit 0 on success, non-zero on failure. The core prints [OK]/[FAIL].
# - No EXIT_CODE=$? block: set -e already stops on the first failing command.
# - Privileges are requested here (sudo/doas), never by the core: flatpak, pipx,
#   brew, yay and paru misbehave or refuse to run as root.
# - Custom modules must not reuse an official name, or modules.sh will overwrite
#   them on the next sync.