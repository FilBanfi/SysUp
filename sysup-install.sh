#!/usr/bin/env bash
# Downloads one module from the official repo and registers it in plugin.conf.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
    cat <<'EOF'
Usage: sysup-install [options] <module-name>

Options:
  --disable   register the module as disabled (=0) instead of enabled
  --force     download again even if already installed
  -h, --help  show this message

Examples:
  sysup-install dnf
  sysup-install --disable snap
  sysup-install --force yay
EOF
}

ENABLE=1
FORCE=0
MODULE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --disable) ENABLE=0; shift ;;
        --force)   FORCE=1;  shift ;;
        -h|--help) usage; exit 0 ;;
        -*) err "Unknown option: $1"; usage; exit 2 ;;
        *)  MODULE="$1"; shift ;;
    esac
done

if [[ -z "$MODULE" ]]; then usage; exit 2; fi

if [[ "$MODULE" != *.sh ]]; then MODULE="$MODULE.sh"; fi

# Flat namespace: rejecting slashes makes path traversal impossible by construction.
if [[ "$MODULE" == */* || "$MODULE" == *[[:space:]]* || "$MODULE" == ".sh" ]]; then
    err "Invalid module name: $MODULE"
    err "Use the plain name, e.g. sysup-install dnf"
    exit 2
fi

dest="$SYSUP_MODULES/$MODULE"
url="$SYSUP_RAW/modules/$MODULE"

if [[ -f "$dest" ]] && (( FORCE == 0 )); then
    warn "Already installed: $MODULE"
    warn "To download again: sysup-install --force ${MODULE%.sh}"
    exit 0
fi

# ===== DOWNLOAD =====
mkdir -p "$SYSUP_MODULES"

# Temp file + mv, so an interrupted download never leaves a half-written module.
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

info "Downloading $MODULE (ref: $SYSUP_REF)..."
if ! fetch "$url" "$tmp"; then
    err "Module not found in the official repository, or network unavailable."
    err "URL: $url"
    exit 1
fi

# Catches HTML error pages served with HTTP 200 by some proxies.
first=""
IFS= read -r first < "$tmp" || true
if [[ "$first" != \#* ]]; then
    err "Downloaded file is not a valid script. Aborted."
    exit 1
fi

mv "$tmp" "$dest"
chmod +x "$dest"
ok "Installed: $MODULE"

# ===== REGISTER =====
if [[ ! -f "$SYSUP_CONFIG" ]]; then
    warn "plugin.conf not found: creating it."
    printf '# config-version: %s\n' "$SYSUP_CONFIG_VERSION" > "$SYSUP_CONFIG"
fi

if grep -q "^${MODULE}=" "$SYSUP_CONFIG"; then
    warn "Already in plugin.conf: leaving your setting untouched."
else
    printf '\n# added by sysup-install\n%s=%s\n' "$MODULE" "$ENABLE" >> "$SYSUP_CONFIG"
    if (( ENABLE == 1 )); then
        ok "Added to plugin.conf and enabled."
    else
        ok "Added to plugin.conf but disabled (=0)."
    fi
fi