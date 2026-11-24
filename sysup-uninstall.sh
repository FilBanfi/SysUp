#!/usr/bin/env bash
# Removes the tool, its commands and the PATH lines it added.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

ASSUME_YES=0
if [[ "${1:-}" == "-y" || "${1:-}" == "--yes" ]]; then ASSUME_YES=1; fi

printf '%s\n' "${C_GREEN}======================================"
printf '%s\n' "      SYSUP UNINSTALLER v$SYSUP_VERSION"
printf '%s\n' "======================================${C_RESET}"
echo ""

if (( ASSUME_YES == 0 )); then
    if [[ ! -t 0 ]]; then err "No interactive terminal: use 'sysup-uninstall -y'."; exit 1; fi
    warn "This removes $SYSUP_INSTALL_DIR (modules and plugin.conf included)."
    read -rp "Continue? [y/N]: " ans
    case "$ans" in y|Y|yes|YES) ;; *) echo "Aborted."; exit 0 ;; esac
fi

# ===== COMMANDS =====
info "Removing commands..."
for cmd in sysup sysup-install sysup-remove sysup-uninstall sysup-help; do
    rm -f "$SYSUP_BIN_DIR/$cmd"
done
ok "Commands removed."

# ===== SHELL RC =====
# Removal by marker: no fragile regex matching against $PATH.
info "Cleaning .bashrc / .zshrc..."
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc" ]] && grep -Fq 'sysup' "$rc"; then
        sed_i '/# sysup-path/d' "$rc"
        sed_i '/# Added by sysup installer/d' "$rc"
        ok "Cleaned $(basename "$rc")"
    fi
done

# ===== DIRECTORY =====
# Guard before rm -rf: only delete a path that really ends in /sysup.
if [[ -n "$SYSUP_INSTALL_DIR" && "$SYSUP_INSTALL_DIR" == */sysup && -d "$SYSUP_INSTALL_DIR" ]]; then
    info "Removing installation directory..."
    rm -rf "$SYSUP_INSTALL_DIR"
    ok "Directory removed."
else
    warn "Directory not removed (unexpected path or already gone): $SYSUP_INSTALL_DIR"
fi

echo ""
printf '%s\n' "${C_GREEN}======================================"
printf '%s\n' "      UNINSTALLATION COMPLETED"
printf '%s\n' "======================================${C_RESET}"
echo ""
info "Reopen your terminal, or run 'source ~/.bashrc', to apply PATH changes."