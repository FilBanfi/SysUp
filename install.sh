#!/usr/bin/env bash
# =============================================================================
# install.sh — installa il CORE di sysup in ~/.local/share/sysup.
# I moduli dei package manager NON vengono installati qui: si scaricano
# on-demand con sysup-install, così il tool non si porta dietro roba inutile.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

printf '%s\n' "${C_GREEN}======================================"
printf '%s\n' "        SYSUP INSTALLER v$SYSUP_VERSION"
printf '%s\n' "           by FilBanfi"
printf '%s\n' "======================================${C_RESET}"
echo ""

# ===== VERIFICA SORGENTI =====
# Ci assicuriamo di essere in un clone completo, non in una cartella a caso
# con dentro un install.sh scaricato da solo.
for required in sysup.sh sysup-install.sh sysup-remove.sh sysup-uninstall.sh \
                lib/common.sh plugin.conf.example \
                modules/core.sh modules/modules.sh modules/template.sh; do
    if [[ ! -e "$SCRIPT_DIR/$required" ]]; then
        err "Sorgente incompleto: manca '$required'."
        err "Esegui install.sh dalla root del repository clonato."
        exit 1
    fi
done

# ===== DIRECTORY =====
info "Creo le directory..."
mkdir -p "$SYSUP_INSTALL_DIR" "$SYSUP_BIN_DIR"

# ===== COPIA MIRATA =====
# Solo ciò che serve: niente .git, README, LICENSE o file spuri.
info "Copio i file del core..."
cp "$SCRIPT_DIR/sysup.sh" \
   "$SCRIPT_DIR/sysup-install.sh" \
   "$SCRIPT_DIR/sysup-remove.sh" \
   "$SCRIPT_DIR/sysup-uninstall.sh" \
   "$SCRIPT_DIR/plugin.conf.example" \
   "$SYSUP_INSTALL_DIR/"

mkdir -p "$SYSUP_INSTALL_DIR/lib" "$SYSUP_INSTALL_DIR/modules"
cp "$SCRIPT_DIR/lib/common.sh" "$SYSUP_INSTALL_DIR/lib/"
cp "$SCRIPT_DIR/modules/core.sh" \
   "$SCRIPT_DIR/modules/modules.sh" \
   "$SCRIPT_DIR/modules/template.sh" \
   "$SYSUP_INSTALL_DIR/modules/"

# ===== VERIFICA =====
if [[ ! -f "$SYSUP_INSTALL_DIR/sysup.sh" || ! -f "$SYSUP_INSTALL_DIR/lib/common.sh" ]]; then
    err "Installazione fallita: file del core mancanti."
    exit 1
fi

# ===== CONFIG =====
# Il plugin.conf dell'utente non viene MAI sovrascritto: è roba sua.
if [[ ! -f "$SYSUP_INSTALL_DIR/plugin.conf" ]]; then
    cp "$SYSUP_INSTALL_DIR/plugin.conf.example" "$SYSUP_INSTALL_DIR/plugin.conf"
    ok "plugin.conf creato."
else
    warn "plugin.conf già esistente: lo lascio intatto."
fi

# ===== PERMESSI =====
chmod +x "$SYSUP_INSTALL_DIR/"*.sh
find "$SYSUP_INSTALL_DIR/modules" -type f -name '*.sh' -exec chmod +x {} +

# ===== COMANDI (WRAPPER, NON SYMLINK) =====
# Con un symlink, BASH_SOURCE[0] sarebbe ~/.local/bin/sysup e il core cercherebbe
# lib/ e plugin.conf nella cartella bin. Il wrapper evita il problema senza
# bisogno di readlink -f, che su BSD/macOS non è garantito.
make_wrapper() {
    local name="$1" target="$2"
    cat > "$SYSUP_BIN_DIR/$name" <<EOF
#!/usr/bin/env bash
# Wrapper generato da sysup install.sh — non modificare a mano.
exec "$target" "\$@"
EOF
    chmod +x "$SYSUP_BIN_DIR/$name"
}

info "Creo i comandi..."
make_wrapper sysup           "$SYSUP_INSTALL_DIR/sysup.sh"
make_wrapper sysup-install   "$SYSUP_INSTALL_DIR/sysup-install.sh"
make_wrapper sysup-remove    "$SYSUP_INSTALL_DIR/sysup-remove.sh"
make_wrapper sysup-uninstall "$SYSUP_INSTALL_DIR/sysup-uninstall.sh"
ok "Comandi creati in $SYSUP_BIN_DIR"

# ===== PATH =====
# Il marcatore "# sysup-path" rende la rimozione banale e sicura.
if [[ ":$PATH:" != *":$SYSUP_BIN_DIR:"* ]]; then
    info "Configuro il PATH..."
    added=0
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$rc" ]] && ! grep -Fq '# sysup-path' "$rc"; then
            printf '\n# Added by sysup installer\nexport PATH="%s:$PATH" # sysup-path\n' \
                "$SYSUP_BIN_DIR" >> "$rc"
            ok "PATH aggiunto a $(basename "$rc")"
            added=1
        fi
    done
    if (( added == 0 )); then
        warn "Nessun .bashrc/.zshrc modificato: aggiungi $SYSUP_BIN_DIR al PATH a mano."
    fi
else
    ok "$SYSUP_BIN_DIR è già nel PATH."
fi

echo ""
printf '%s\n' "${C_GREEN}======================================"
printf '%s\n' "       INSTALLAZIONE COMPLETATA"
printf '%s\n' "======================================${C_RESET}"
echo ""
echo "Comandi: sysup | sysup-install | sysup-remove | sysup-uninstall"
echo ""
echo "Prossimo passo: installa i moduli che ti servono, es."
echo "  sysup-install dnf"
echo "  sysup-install flatpak"
echo ""
echo "Poi apri $SYSUP_INSTALL_DIR/plugin.conf e ordina i moduli come preferisci."