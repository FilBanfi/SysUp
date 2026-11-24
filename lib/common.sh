#!/usr/bin/env bash
# =============================================================================
# lib/common.sh — libreria condivisa dagli script del CORE.
#
# NON viene usata dai moduli: i moduli restano autonomi, così chiunque può
# scriverne uno senza sapere nulla di questa libreria.
#
# Caricata con "source": non va eseguita direttamente e non serve set -euo
# pipefail qui, lo imposta già lo script che la carica.
# =============================================================================

# --- Versione del core -------------------------------------------------------
# Unico posto dove si tocca la versione del programma. I moduli hanno la loro,
# perché hanno un ciclo di sviluppo separato.
SYSUP_VERSION="0.4.0"

# Versione del FORMATO di plugin.conf che questo core sa leggere.
# Se il conf dichiara un numero più alto, il core si ferma invece di
# comportarsi in modo indefinito.
SYSUP_CONFIG_VERSION=1

# --- Sorgente dei moduli -----------------------------------------------------
# Branch da cui pescare. Ciò che entra in main è stabile, quindi main è il
# default. La variabile d'ambiente serve solo per provare un branch di lavoro:
#   SYSUP_REF=test sysup-install --force dnf
SYSUP_REF="${SYSUP_REF:-main}"
SYSUP_RAW="https://raw.githubusercontent.com/filbanfi/sysup/${SYSUP_REF}"

# --- Percorsi ----------------------------------------------------------------
# SYSUP_HOME = cartella che CONTIENE lib/, cioè la root del progetto.
# Funziona sia nel clone sia nell'installazione perché i comandi in ~/.local/bin
# sono wrapper, non symlink: BASH_SOURCE punta sempre al file vero.
SYSUP_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYSUP_MODULES="$SYSUP_HOME/modules"
SYSUP_CONFIG="$SYSUP_HOME/plugin.conf"

# Destinazione dell'installazione (usata da install.sh / sysup-uninstall.sh).
SYSUP_INSTALL_DIR="${SYSUP_INSTALL_DIR:-$HOME/.local/share/sysup}"
SYSUP_BIN_DIR="${SYSUP_BIN_DIR:-$HOME/.local/bin}"

# Lock: XDG_RUNTIME_DIR è per-utente e viene svuotata al logout.
# Fallback /tmp per i sistemi che non ce l'hanno.
SYSUP_LOCK="${XDG_RUNTIME_DIR:-/tmp}/sysup.lock"

# --- Colori ------------------------------------------------------------------
# Se stdout non è un terminale (pipe, log, cron) i colori si disattivano:
# niente escape ANSI spazzatura nei file di log.
if [[ -t 1 ]]; then
    C_GREEN=$'\033[32m'; C_RED=$'\033[31m'; C_YELLOW=$'\033[33m'; C_RESET=$'\033[0m'
else
    C_GREEN=''; C_RED=''; C_YELLOW=''; C_RESET=''
fi

# --- Log ---------------------------------------------------------------------
# printf invece di "echo -e": echo -e non è POSIX e cambia comportamento tra
# bash/dash/sh. printf è prevedibile ovunque.
info() { printf '%s\n' "${C_YELLOW}[INFO]${C_RESET} $*"; }
ok()   { printf '%s\n' "${C_GREEN}[OK]${C_RESET} $*"; }
warn() { printf '%s\n' "${C_YELLOW}[WARN]${C_RESET} $*"; }
err()  { printf '%s\n' "${C_RED}[ERROR]${C_RESET} $*" >&2; }
rule() { printf '%s\n' "${C_YELLOW}======================================${C_RESET}"; }

# --- Utility -----------------------------------------------------------------

# have <comando> → vero se il comando è nel PATH.
have() { command -v "$1" >/dev/null 2>&1; }

# trim <stringa> → stringa senza spazi iniziali/finali.
# Gli spazi INTERNI restano: un nome file con spazi è errore dell'utente.
trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"   # spazi iniziali
    s="${s%"${s##*[![:space:]]}"}"   # spazi finali
    printf '%s' "$s"
}

# fetch <url> <destinazione>
# curl è lo standard per scaricare file singoli: niente .git, niente metadati,
# niente conflitti. wget come fallback. 127 = nessuno dei due installato.
# -f fa fallire curl su HTTP 404/500: è così che capiamo "modulo inesistente".
fetch() {
    local url="$1" dest="$2"
    if have curl; then
        curl -fsSL --connect-timeout 10 --max-time 120 --retry 2 "$url" -o "$dest"
    elif have wget; then
        wget -q --timeout=15 --tries=2 "$url" -O "$dest"
    else
        return 127
    fi
}

# sed_i <espressione> <file> → sed in-place portabile.
# GNU sed accetta -i senza argomento, BSD/macOS sed vuole -i ''.
# "sed --version" esiste solo su GNU: lo usiamo come test.
sed_i() {
    if sed --version >/dev/null 2>&1; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}