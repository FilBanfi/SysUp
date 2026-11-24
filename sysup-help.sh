#!/usr/bin/env bash
# User-facing documentation. Keep the module list in sync with modules/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

VERSION="0.1.0"

case "${1:-}" in
    -v|--version) printf 'sysup-help %s\n' "$VERSION"; exit 0 ;;
esac

cat <<EOF
${C_GREEN}======================================
           SYSUP HELP v$VERSION
======================================${C_RESET}

${C_YELLOW}WHAT IT IS${C_RESET}
  A modular system updater. It runs the modules you enable, in the order you
  write them. No distribution detection: you decide what runs and when.

${C_YELLOW}COMMANDS${C_RESET}
  sysup                          run the enabled modules
  sysup -y                       skip the confirmation prompt (cron, scripts)
  sysup -v                       print the core version
  sysup-install <name>           download a module and enable it
  sysup-install --disable <name> download it but leave it disabled
  sysup-install --force <name>   download again, overwriting the local copy
  sysup-remove <name>            delete a module and its config line
  sysup-uninstall                remove sysup, its commands and its PATH lines
  sysup-help                     this documentation

${C_YELLOW}QUICK START${C_RESET}
  1. bash install.sh
  2. sysup-install dnf
  3. sysup-install flatpak
  4. edit plugin.conf to set the execution order
  5. sysup

${C_YELLOW}CONFIG FILE${C_RESET}
  ${SYSUP_CONFIG}

  Format: name.sh=1        1 = enabled, 0 = disabled

  - Line order is execution order. There is no dependency resolver.
  - One module per line. No spaces in file names.
  - Lines starting with # are ignored.
  - Keep the "# config-version: 1" line: the core checks it for compatibility.
  - This file is never overwritten by install or updates.

${C_YELLOW}AVAILABLE MODULES${C_RESET}
  Use the name without .sh, e.g. sysup-install dnf
  
  Modules my vary from this list. Please always refere to the official list on GitHub.
  
  Arch          pacman  yay  paru
  Debian        apt
  Fedora        dnf
  openSUSE      zypper (Leap/SLE)  zypper-dup (Tumbleweed)
  Gentoo        emerge
  Nix           nix (package manager)  nixos (NixOS only)
  BSD           pkg (FreeBSD)  pkg_add (OpenBSD)  pkgin (NetBSD)
  Alpine        apk
  Void          xbps
  macOS         brew
  Universal     flatpak  snap
  Dev tools     pipx  fisher  rustup
  Maintenance   core  modules

  core.sh       updates the sysup core files
  modules.sh    updates every module installed locally
  Keep both enabled and first in plugin.conf.

${C_YELLOW}FILES${C_RESET}
  ${SYSUP_INSTALL_DIR}
      core scripts, lib/, modules/, plugin.conf
  ${SYSUP_BIN_DIR}
      command wrappers
  ${XDG_RUNTIME_DIR:-/tmp}/sysup.lock
      run lock, held by the kernel while sysup is running

${C_YELLOW}REQUIREMENTS${C_RESET}
  bash, curl or wget, flock
  macOS:   brew install flock
  OpenBSD: pkg_add flock

  Privileges are requested by each module (sudo or doas), never by sysup itself.
  Tools like flatpak, pipx, brew, yay and paru must not run as root.

${C_YELLOW}EXIT CODES${C_RESET}
  0  everything succeeded
  1  at least one module failed
  2  invalid usage

${C_YELLOW}TROUBLESHOOTING${C_RESET}
  "sysup is already running"
      Another instance holds the lock. The lock is released automatically when
      that process exits, including on Ctrl+C.

  "module not installed: <name>"
      The config references a module that is not on disk.
      Fix: sysup-install <name>

  "flock is required"
      Install flock with your package manager (see REQUIREMENTS).

  "plugin.conf is format vN"
      Your config is newer than this core. Update the core:
      bash ${SYSUP_MODULES}/core.sh

  A module prints FAIL
      The core keeps going with the next module. Read the module output above
      the FAIL line: the error comes from the package manager, not from sysup.

  Nothing runs
      Check that the lines you want end with =1, not =0.

${C_YELLOW}MORE${C_RESET}
  Repository: https://github.com/filbanfi/sysup
  License:    GPL-3.0
EOF