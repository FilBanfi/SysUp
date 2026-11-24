# SysUp

![Version](https://img.shields.io/badge/version-0.4.0-blue) ![License](https://img.shields.io/badge/license-GPL--3.0-green) ![Language](https://img.shields.io/badge/language-Shell-red)

**Modular system updater for Unix-like systems.**

SysUp is a lightweight, transparent, and highly customizable system updater. Unlike tools that auto-detect and blindly execute updates, `sysup` gives you absolute control: you decide exactly which modules run, in what order, and you can easily write your own modules to update any obscure CLI tool, custom GitHub script, or personal workflow.

---

## Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/filbanfi/sysup.git
cd sysup
bash install.sh
```

*Note: macOS and OpenBSD users must install `flock` first (`brew install flock` or `pkg_add flock`).*

---

## Quick Start

1. **Install a module** (e.g., `dnf`):
```bash
   sysup-install dnf
```
   *(This downloads the module and enables it automatically. Use `--disable` if you only want to download it).*
2. **Check the order** by editing `~/.local/share/sysup/plugin.conf`. The line order determines the execution order.
3. **Run the updater**:
```bash
   sysup
```

For a complete list of commands, configuration rules, and troubleshooting, run:
```bash
sysup-help
```

---

## Why SysUp?

- **Total Transparency:** Every module is a short, readable shell script. No compiled binaries, no hidden logic. You know exactly what will run with elevated privileges.
- **Absolute Control:** Execution order is defined strictly by the line order in `plugin.conf`. No hardcoded sequences.
- **Infinitely Extensible:** Write your own `.sh` module to update a niche tool, a personal script, or a specific repository, and drop it in the `modules/` directory. No compilation or complex PR process required.
- **Minimal Footprint:** The core is just a few kilobytes of shell scripts, compared to multi-megabyte compiled binaries. Modules are downloaded on-demand, keeping your disk usage negligible.

---

## Comparison: SysUp vs topgrade

[topgrade](https://github.com/topgrade-rs/topgrade) is a mature tool that solves the same problem with auto-detection and a massive built-in scope. `sysup` takes the opposite design philosophy:

| Feature | topgrade | sysup |
| :--- | :--- | :--- |
| **Implementation** | Compiled Rust binary (several MBs) | Plain, readable Shell scripts (few KBs) |
| **Execution Order** | Hardcoded (with limited `first`/`last` overrides) | Fully customizable via `plugin.conf` line order |
| **Extensibility** | Requires Rust knowledge and a PR to the main repo | Write a 10-line `.sh` script, no compilation needed |
| **Transparency** | Logic is hidden behind compiled code | Every command executed is visible in the module file |
| **Scope** | Massive auto-detection of hundreds of tools | Explicit, on-demand modules (keeps the system lean) |
| **Custom Scripts** | Limited to TOML command hooks | First-class citizens (just add your own module) |
| **Disk Usage** | Heavy binary + dependencies | Negligible, downloads only what you enable |

---

## Platform Support

| Status | Platforms |
| :--- | :--- |
| **Supported & Tested** | Linux (Debian/Ubuntu, Fedora, Arch) |
| **Supported & Untested** | Linux (Gentoo, NixOS, Alpine, Void), macOS, BSD (FreeBSD, OpenBSD, NetBSD), WSL |
| **Unsupported** | Windows (native), non-POSIX environments |

---

## Module Submission

Want to add a new module or update an existing one? Send your `.sh` script to **filbanfi@hotmail.com** with the exact subject line:

```text
SYSUP MODULE SUBMISSION [MODULE NAME]
```

**Module Contract:**
- Must be a standalone, non-interactive bash script.
- Must request its own privileges (`sudo` or `doas`) internally.
- Must exit with `0` on success and non-zero on failure.
- Must not contain spaces in the filename.

---

## License

This project is licensed under the [GPL-3.0 License](LICENSE).