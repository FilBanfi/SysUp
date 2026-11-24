#!/usr/bin/env bash
# =============================================================================
# sysup-install.sh — scarica UN modulo dal repo ufficiale e lo registra nel conf.
#
#   sysup-install dnf              → modules/dnf.sh, abilitato
#   sysup-install --disable snap   → scaricato ma disabilitato
#   sysup-install --force dnf      → riscarica anche se già presente
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
    cat <<'EOF'
Uso: sysup-install [opzioni] <nome-modulo>

Opzioni:
  --disable   registra il modulo come disabilitato (=0) invece che abilitato
  --force     riscarica anche se il modulo è già installato
  -h, --help  questo messaggio

Esempi:
  sysup-install dnf
  sysup-install --disable snap
  sysup-install --force yay
EOF
}

ENABLE=1          # chi installa un modulo lo vuole usare: default abilitato
FORCE=0
MODULE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --disable) ENABLE=0; shift ;;
        --force)   FORCE=1;  shift ;;
        -h|--help) usage; exit 0 ;;
        -*) err "Opzione sconosciuta: $1"; usage; exit 2 ;;
        *)  MODULE="$1"; shift ;;
    esac
done

if [[ -z "$MODULE" ]]; then usage; exit 2; fi

# ===== NORMALIZZAZIONE =====
if [[ "$MODULE" != *.sh ]]; then MODULE="$MODULE.sh"; fi

# ===== VALIDAZIONE =====
# Lista piatta: nessuno slash consentito. Questo rende impossibile il path
# traversal senza dover controllare ".." o i path assoluti.
if [[ "$MODULE" == */* || "$MODULE" == *[[:space:]]* || "$MODULE" == ".sh" ]]; then
    err "Nome modulo non valido: $MODULE"
    err "Usa il nome semplice, es: sysup-install dnf"
    exit 2
fi

dest="$SYSUP_MODULES/$MODULE"
url="$SYSUP_RAW/modules/$MODULE"

if [[ -f "$dest" ]] && (( FORCE == 0 )); then
    warn "Già installato: $MODULE"
    warn "Per riscaricarlo: sysup-install --force ${MODULE%.sh}"
    exit 0
fi

# ===== DOWNLOAD =====
mkdir -p "$SYSUP_MODULES"

# Scarichiamo in un temporaneo e poi mv: un download interrotto non lascia mai
# un modulo mezzo scritto nella cartella modules.
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

info "Scarico $MODULE (ref: $SYSUP_REF)..."
if ! fetch "$url" "$tmp"; then
    err "Modulo non trovato nel repo ufficiale, oppure rete non disponibile."
    err "URL: $url"
    exit 1
fi

# Sanity check sulla prima riga: intercetta le pagine HTML di errore che alcuni
# proxy restituiscono con HTTP 200. Read invece di "head | grep" per non risking
# SIGPIPE con pipefail attivo.
first=""
IFS= read -r first < "$tmp" || true
if [[ "$first" != \#* ]]; then
    err "Il file scaricato non è uno script valido. Annullato."
    exit 1
fi

mv "$tmp" "$dest"
chmod +x "$dest"
ok "Installato: $MODULE"

# ===== REGISTRAZIONE NEL CONF =====
if [[ ! -f "$SYSUP_CONFIG" ]]; then
    warn "plugin.conf non trovato: lo creo da zero."
    printf '# config-version: %s\n' "$SYSUP_CONFIG_VERSION" > "$SYSUP_CONFIG"
fi

if grep -q "^${MODULE}=" "$SYSUP_CONFIG"; then
    warn "Già presente in plugin.conf: non tocco la tua scelta."
else
    printf '\n# aggiunto da sysup-install\n%s=%s\n' "$MODULE" "$ENABLE" >> "$SYSUP_CONFIG"
    if (( ENABLE == 1 )); then
        ok "Aggiunto a plugin.conf e ABILITATO."
    else
        ok "Aggiunto a plugin.conf ma DISABILITATO (=0)."
    fi
fi