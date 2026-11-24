#!/usr/bin/env bash
# =============================================================================
# sysup-remove.sh — rimuove un modulo installato e la sua riga in plugin.conf.
# NB: NON disinstalla sysup. Per quello c'è sysup-uninstall.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

MODULE="${1:-}"
if [[ -z "$MODULE" ]]; then
    err "Uso: sysup-remove <nome-modulo>   (es. sysup-remove paru)"
    exit 2
fi

if [[ "$MODULE" != *.sh ]]; then MODULE="$MODULE.sh"; fi
if [[ "$MODULE" == */* || "$MODULE" == *[[:space:]]* || "$MODULE" == ".sh" ]]; then
    err "Nome modulo non valido: $MODULE"; exit 2
fi

file="$SYSUP_MODULES/$MODULE"

if [[ -f "$file" ]]; then
    rm -f "$file"
    ok "Rimosso: $MODULE"
else
    warn "Modulo non presente sul disco: $MODULE"
fi

# Tolgo la riga dal conf. Uso cat invece di mv per preservare inode e permessi
# del file originale. "|| true" perché grep -v esce 1 se non produce output.
if [[ -f "$SYSUP_CONFIG" ]] && grep -q "^${MODULE}=" "$SYSUP_CONFIG"; then
    tmp="$(mktemp)"
    grep -v "^${MODULE}=" "$SYSUP_CONFIG" > "$tmp" || true
    cat "$tmp" > "$SYSUP_CONFIG"
    rm -f "$tmp"
    ok "Riga rimossa da plugin.conf."
fi