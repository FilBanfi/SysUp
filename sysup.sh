#!/usr/bin/env bash
# =============================================================================
# sysup.sh — legge plugin.conf ed esegue i moduli abilitati nell'ordine scritto.
# Nessun rilevamento della distro: ordine e scelta sono dell'utente.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# ===== ARGOMENTI =====
ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes)     ASSUME_YES=1 ;;
        -h|--help)    printf 'Uso: sysup [-y|--yes]\n'; exit 0 ;;
        -v|--version) printf 'sysup %s\n' "$SYSUP_VERSION"; exit 0 ;;
        *) err "Opzione sconosciuta: $arg"; exit 2 ;;
    esac
done

# ===== HEADER =====
printf '%s\n' "${C_GREEN}======================================"
printf '%s\n' "           SYSUP v$SYSUP_VERSION"
printf '%s\n' "   Universal Linux System Updater"
printf '%s\n' "           by FilBanfi"
printf '%s\n' "======================================${C_RESET}"
echo ""

# ===== CONFIG: ESISTENZA E VERSIONE =====
if [[ ! -f "$SYSUP_CONFIG" ]]; then
    err "plugin.conf non trovato in $SYSUP_HOME"
    err "Reinstalla, o copia plugin.conf.example in plugin.conf."
    exit 1
fi

# Legge "# config-version: N". È un commento, così il parser dei moduli lo ignora.
conf_ver="$(sed -n 's/^# config-version:[[:space:]]*\([0-9]\{1,\}\).*/\1/p' "$SYSUP_CONFIG" | head -n1)"
if [[ -z "$conf_ver" ]]; then
    warn "plugin.conf senza versione: assumo formato $SYSUP_CONFIG_VERSION."
elif (( conf_ver > SYSUP_CONFIG_VERSION )); then
    err "plugin.conf è in formato v$conf_ver, questo core arriva a v$SYSUP_CONFIG_VERSION."
    err "Aggiorna il core: bash $SYSUP_MODULES/core.sh"
    exit 1
fi

# ===== LOCK =====
# flock è gestito dal kernel: atomico, immune ai symlink attack, si rilascia da
# solo anche su Ctrl+C o kill -9. Il file resta su disco vuoto ed è innocuo:
# il concetto di "stale lock" non esiste più.
if ! have flock; then
    err "Serve 'flock'. macOS: brew install flock | OpenBSD: pkg_add flock"
    exit 1
fi
exec 9>"$SYSUP_LOCK"          # apre il file sul fd 9 (NON blocca nulla)
if ! flock -n 9; then         # -n = non bloccante: se occupato, fallisce subito
    err "sysup è già in esecuzione."
    exit 1
fi

# ===== CONFERMA =====
if (( ASSUME_YES == 0 )); then
    # Senza terminale (cron, pipe) non chiediamo nulla: meglio uscire che
    # restare appesi ad aspettare un input che non arriverà mai.
    if [[ ! -t 0 ]]; then
        err "Nessun terminale interattivo: usa 'sysup -y'."
        exit 1
    fi
    read -rp "Continuare con l'aggiornamento? [y/N]: " ans
    case "$ans" in
        y|Y|yes|YES) ;;
        *) echo "Annullato."; exit 0 ;;
    esac
fi

echo ""
info "Avvio aggiornamento..."
echo ""

# ===== ESECUZIONE MODULI =====
n_ok=0; n_fail=0; n_skip=0

# "|| [[ -n "$raw_path" ]]" → processa anche l'ultima riga del conf se il file
# non finisce con un newline (read restituisce falso ma i dati li ha letti).
while IFS='=' read -r raw_path raw_flag || [[ -n "$raw_path" ]]; do

    path="$(trim "$raw_path")"
    flag="$(trim "${raw_flag:-}")"

    if [[ -z "$path" ]]; then continue; fi
    if [[ "$path" == \#* ]]; then continue; fi
    if [[ "$flag" != "1" ]]; then n_skip=$((n_skip+1)); continue; fi

    file="$SYSUP_MODULES/$path"
    rule

    if [[ ! -f "$file" ]]; then
        warn "modulo non installato: $path"
        warn "installalo con: sysup-install ${path%.sh}"
        n_fail=$((n_fail+1))
        echo ""
        continue
    fi

    info "RUN $path"
    # L'if assorbe l'exit code: con set -e un modulo fallito NON ammazza il core,
    # viene contato come FAIL e si passa al successivo.
    if bash "$file"; then
        ok "$path"
        n_ok=$((n_ok+1))
    else
        err "FAIL $path"
        n_fail=$((n_fail+1))
    fi
    echo ""

done < "$SYSUP_CONFIG"

# ===== RIEPILOGO =====
# Si usa n=$((n+1)) e non ((n++)): con set -e, ((n++)) vale 0 al primo giro e
# un'espressione aritmetica che vale 0 fa uscire lo script.
rule
printf '%s\n' "${C_GREEN}      AGGIORNAMENTO TERMINATO${C_RESET}"
printf '      ok: %s | falliti: %s | disabilitati: %s\n' "$n_ok" "$n_fail" "$n_skip"
rule

# Exit code utile per cron e script: 1 se qualcosa è fallito.
if (( n_fail > 0 )); then exit 1; fi
exit 0