#!/usr/bin/env bash
# Shared library for the core scripts. Modules do not source this: they stay
# self-contained so anyone can write one without knowing this file exists.

SYSUP_VERSION="0.4.0"

# plugin.conf format this core understands.
SYSUP_CONFIG_VERSION=1

SYSUP_REF="${SYSUP_REF:-main}"
SYSUP_RAW="https://raw.githubusercontent.com/filbanfi/sysup/${SYSUP_REF}"

# Root of the project: works both in the clone and in the install dir, because
# the commands in ~/.local/bin are wrappers, not symlinks.
SYSUP_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYSUP_MODULES="$SYSUP_HOME/modules"
SYSUP_CONFIG="$SYSUP_HOME/plugin.conf"

SYSUP_INSTALL_DIR="${SYSUP_INSTALL_DIR:-$HOME/.local/share/sysup}"
SYSUP_BIN_DIR="${SYSUP_BIN_DIR:-$HOME/.local/bin}"
SYSUP_LOCK="${XDG_RUNTIME_DIR:-/tmp}/sysup.lock"

# ===== COLORS =====
# Disabled when stdout is not a terminal, to keep ANSI codes out of logs.
if [[ -t 1 ]]; then
    C_GREEN=$'\033[32m'; C_RED=$'\033[31m'; C_YELLOW=$'\033[33m'; C_RESET=$'\033[0m'
else
    C_GREEN=''; C_RED=''; C_YELLOW=''; C_RESET=''
fi

# ===== LOG =====
# printf, not echo -e: the latter is not POSIX and varies across shells.
info() { printf '%s\n' "${C_YELLOW}[INFO]${C_RESET} $*"; }
ok()   { printf '%s\n' "${C_GREEN}[OK]${C_RESET} $*"; }
warn() { printf '%s\n' "${C_YELLOW}[WARN]${C_RESET} $*"; }
err()  { printf '%s\n' "${C_RED}[ERROR]${C_RESET} $*" >&2; }
rule() { printf '%s\n' "${C_YELLOW}======================================${C_RESET}"; }

# ===== HELPERS =====

have() { command -v "$1" >/dev/null 2>&1; }

# Strips leading/trailing whitespace only. Inner spaces are left alone.
trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# Returns 127 when neither downloader is available.
# curl -f is what turns HTTP 404 into a failure, i.e. "module not found".
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

# GNU sed takes -i with no argument, BSD/macOS sed requires -i ''.
sed_i() {
    if sed --version >/dev/null 2>&1; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}