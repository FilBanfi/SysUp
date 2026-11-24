#!/usr/bin/env bash
# Runs the enabled modules in the order they appear in plugin.conf.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# ===== ARGS =====
ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes)     ASSUME_YES=1 ;;
        -h|--help)    printf 'Usage: sysup [-y|--yes]\n'; exit 0 ;;
        -v|--version) printf 'sysup %s\n' "$SYSUP_VERSION"; exit 0 ;;
        *) err "Unknown option: $arg"; exit 2 ;;
    esac
done

# ===== HEADER =====
printf '%s\n' "${C_GREEN}======================================"
printf '%s\n' "           SYSUP v$SYSUP_VERSION"
printf '%s\n' "   Universal Linux System Updater"
printf '%s\n' "           by FilBanfi"
printf '%s\n' "======================================${C_RESET}"
echo ""

# ===== CONFIG =====
if [[ ! -f "$SYSUP_CONFIG" ]]; then
    err "plugin.conf not found in $SYSUP_HOME"
    err "Reinstall, or copy plugin.conf.example to plugin.conf."
    exit 1
fi

# A newer config format could be silently misread, so refuse it.
conf_ver="$(sed -n 's/^# config-version:[[:space:]]*\([0-9]\{1,\}\).*/\1/p' "$SYSUP_CONFIG" | head -n1)"
if [[ -z "$conf_ver" ]]; then
    warn "plugin.conf has no version: assuming format $SYSUP_CONFIG_VERSION."
elif (( conf_ver > SYSUP_CONFIG_VERSION )); then
    err "plugin.conf is format v$conf_ver, this core supports up to v$SYSUP_CONFIG_VERSION."
    err "Update the core: bash $SYSUP_MODULES/core.sh"
    exit 1
fi

# ===== LOCK =====
# Kernel-managed: atomic, symlink-safe, released on exit or kill. No stale locks.
if ! have flock; then
    err "flock is required. macOS: brew install flock | OpenBSD: pkg_add flock"
    exit 1
fi
exec 9>"$SYSUP_LOCK"
if ! flock -n 9; then
    err "sysup is already running."
    exit 1
fi

# ===== CONFIRM =====
if (( ASSUME_YES == 0 )); then
    # Without a tty, waiting for input would hang forever (cron, pipes).
    if [[ ! -t 0 ]]; then
        err "No interactive terminal: use 'sysup -y'."
        exit 1
    fi
    read -rp "Continue with system update? [y/N]: " ans
    case "$ans" in
        y|Y|yes|YES) ;;
        *) echo "Aborted."; exit 0 ;;
    esac
fi

echo ""
info "Starting update..."
echo ""

# ===== RUN MODULES =====
n_ok=0; n_fail=0; n_skip=0

# The || clause handles a last line with no trailing newline.
while IFS='=' read -r raw_path raw_flag || [[ -n "$raw_path" ]]; do

    path="$(trim "$raw_path")"
    flag="$(trim "${raw_flag:-}")"

    if [[ -z "$path" ]]; then continue; fi
    if [[ "$path" == \#* ]]; then continue; fi
    if [[ "$flag" != "1" ]]; then n_skip=$((n_skip+1)); continue; fi

    file="$SYSUP_MODULES/$path"
    rule

    if [[ ! -f "$file" ]]; then
        warn "module not installed: $path"
        warn "install it with: sysup-install ${path%.sh}"
        n_fail=$((n_fail+1))
        echo ""
        continue
    fi

    info "RUN $path"
    # if absorbs the exit code, so set -e does not kill the core on a failed module.
    if bash "$file"; then
        ok "$path"
        n_ok=$((n_ok+1))
    else
        err "FAIL $path"
        n_fail=$((n_fail+1))
    fi
    echo ""

done < "$SYSUP_CONFIG"

# ===== SUMMARY =====
# n=$((n+1)) instead of ((n++)): the latter evaluates to 0 on the first
# increment and set -e would abort.
rule
printf '%s\n' "${C_GREEN}      SYSTEM UPDATE COMPLETED${C_RESET}"
printf '      ok: %s | failed: %s | disabled: %s\n' "$n_ok" "$n_fail" "$n_skip"
rule

if (( n_fail > 0 )); then exit 1; fi
exit 0