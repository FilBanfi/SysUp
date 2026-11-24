#!/usr/bin/env bash
# =============================================================================
# sysup-uninstall.sh — rimuove il tool, i comandi e le righe aggiunte al PATH.
# Idempotente: lanciarlo due volte non produce errori.
# =============================================================================
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
    if [[ ! -t 0 ]]; then err "Nessun terminale: usa 'sysup-uninstall -y'."; exit 1; fi
    warn "Rimuovo $SYSUP_INSTALL_DIR (moduli e plugin.conf inclusi)."
    read -rp "Continuare? [y/N]: " ans
    case "$ans" in y|Y|yes|YES) ;; *) echo "Annullato."; exit 0 ;; esac
fi

# ===== COMANDI =====
# -f: se il file non c'è, nessun errore (idempotenza).
info "Rimuovo i comandi..."
for cmd in sysup sysup-install sysup-remove sysup-uninstall; do
    rm -f "$SYSUP_BIN_DIR/$cmd"
done
ok "Comandi rimossi."

# ===== PULIZIA RC =====
# Rimozione per marcatore: niente regex fragili su $PATH.
info "Pulisco .bashrc / .zshrc..."
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc" ]] && grep -Fq 'sysup' "$rc"; then
        sed_i '/# sysup-path/d' "$rc"
        sed_i '/# Added by sysup installer/d' "$rc"
        ok "Pulito $(basename "$rc")"
    fi
done

# ===== DIRECTORY =====
# Guardia: cancelliamo solo se il percorso finisce davvero con /sysup.
if [[ -n "$SYSUP_INSTALL_DIR" && "$SYSUP_INSTALL_DIR" == */sysup && -d "$SYSUP_INSTALL_DIR" ]]; then
    info "Rimuovo la directory di installazione..."
    rm -rf "$SYSUP_INSTALL_DIR"
    ok "Directory rimossa."
else
    warn "Directory non rimossa (percorso inatteso o già assente): $SYSUP_INSTALL_DIR"
fi

echo ""
printf '%s\n' "${C_GREEN}======================================"
printf '%s\n' "      DISINSTALLAZIONE COMPLETATA"
printf '%s\n' "======================================${C_RESET}"
echo ""
info "Riapri il terminale (o 'source ~/.bashrc') per applicare il PATH."