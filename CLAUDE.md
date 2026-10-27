# CLAUDE.md — northstar-osint

Context for Claude Code sessions working on this repository.

## What this is

A modular, source-available (PolyForm Noncommercial 1.0.0) OSINT workstation builder for Debian 13, Ubuntu 24.04,
Kali, Parrot and macOS on Apple Silicon. It's original work: never copy code,
templates or assets from OSINT books, courses or paid products, and don't add
references to them.

## Layout

- `install.sh`: entry point. Parses flags, detects the platform, sources every
  `modules/*.sh`, runs the selected modules through `ns_step`.
- `lib/common.sh`: installer helpers (`ns_apt`, `ns_brew`, `ns_cask`,
  `ns_flatpak`, `ns_pipx`, `ns_go`, `ns_go_ensure`, `ns_git_venv`,
  `ns_gh_release`, `ns_register`, platform detection).
- `lib/ui.sh`: runtime library for menu tools (`ui_*` dialogs via zenity or
  osascript, `ns_outdir`, `ns_run`, `ns_audit`, `ns_finish`, case handling).
- `lib/gen_policies.py`: builds Firefox/Brave policy JSON and a bookmarks export.
- `lib/ns_breach.py`, `lib/ns_darkweb.py`: engines for `ns-breach` and
  `ns-darkweb` (stdlib + curl; API keys read from `~/.config/northstar/keys.env`).
- `lib/ns_vault.py`: the Obsidian case hub behind `ns-notes` (dashboards, result notes,
  findings, selectors, accounts, link chart, chronology, handover, the report's
  vault sections). Everything it renders from collected data goes through
  `cell()`/`code()`/`fence()`/`flink()`; never put raw web-sourced text in a link.
- `lib/ns_country.py`: engine for `ns-country` (reads the country packs, builds
  search links, phone analysis, `validate`).
- `modules/NN-name.sh`: one module each; it registers with
  `ns_register name "desc" "linux macos" mod_name`.
- `tools/`: menu tools installed to `~/.local/share/northstar/bin`.
- `config/bookmarks.json`, `config/firefox-extensions.txt`: data, not code.
- `config/countries/<cc>.json`: one country pack each (searches + bookmark
  folders). Format in `docs/COUNTRIES.md`.
- `assets/wallpaper/`: original desktop wallpaper (PNG) and its generator script.
- `docs/`: user documentation. Keep it in sync with behaviour changes.

## Hard rules

- **Bash 3.2 compatible everywhere** (macOS ships 3.2): no `declare -A`,
  `mapfile`/`readarray`, `${var,,}`/`${var^^}`, `&>>`. Guard empty-array
  expansion under `set -u`.
- Module functions **return** non-zero on failure and never `exit`. One broken
  tool must not stop the install.
- Never remove Debian's `EXTERNALLY-MANAGED` file. Python tools go through pipx
  (`ns_pipx <command> [spec]`) or private venvs (`ns_git_venv`).
- Install only from official sources. Don't vendor third-party binaries.
- Menu tools must log through `ns_run`/`ns_audit`, and must never write secrets
  (cookies, API keys, passwords) to `audit.log`. API keys live only in
  `keys.env` (mode 600) and must never appear on a command line.
- Breach features query lookup services only; never download or store dumps.
  Dark-web fetches are text-only and must not bypass sites' anti-bot measures.
- The installer must run as a normal user; it calls sudo itself.

## Checks to run before committing

```bash
shellcheck -x -S warning install.sh lib/common.sh lib/ui.sh modules/*.sh tools/*
for f in install.sh lib/*.sh modules/*.sh tools/*; do bash -n "$f"; done
grep -nE 'declare -A|local -A|mapfile|readarray|\$\{[A-Za-z_]+(,,|\^\^)|&>>' install.sh lib/*.sh modules/*.sh tools/*
python3 -m py_compile lib/*.py && python3 -m json.tool config/bookmarks.json >/dev/null
python3 lib/ns_country.py validate
bash tests/run.sh                      # offline functional tests (also run in CI)
# after a real install: bash tests/e2e.sh   (CI: .github/workflows/e2e.yml, weekly/on demand)
./install.sh --list
```

CI (`.github/workflows/lint.yml`) runs the same checks.

## Status

First real install passed on 2026-10-26: Debian 13 GNOME, arm64, in a UTM
(QEMU) VM on Apple Silicon. The maintainer has since tested the username menu,
SpiderFoot, Country search, the GNOME tweaks, the wallpaper and the zsh setup
there. Still untested: x86_64 (Proxmox/Kasm, Tor/Mullvad Flatpaks), Ubuntu,
Kali, Parrot, macOS. See CHANGELOG.md for the current version.

## Open work

1. **Amass v5 returns little without API keys.** A passive `amass enum` against
   a real domain (Oct 2026, v5.1.3) stored only the seed name. Check whether
   that's expected without `datasources.yaml` keys before relying on it. The
   engine listens on `:4000` on all interfaces and ignores `-dir` for storage.
2. **arm64 Tor Browser is the alpha.** `ns_tor_browser_tarball` switches to
   stable by itself once the release channel has `linux-aarch64`; then update
   the "alpha" notes in `docs/`. Mullvad Browser still has no arm64 Linux build.
   The signature check has only been reasoned about, not run: confirm the
   installer prints "signature-verified" on the arm64 VM.
3. **Bookmarks to check by hand.** `ns-linkcheck` can't verify sites that block
   scripts (403), including many in the country packs. Government sites in
   Australia, Indonesia, Thailand and Vietnam also drop connections from abroad
   (curl 000); their URLs were confirmed by search in Oct 2026, not by loading.
4. **Pinned workarounds to revisit.** theHarvester is pinned to 4.11.1 on
   Python < 3.14 (`modules/20-domain.sh`); drop the pin once supported distros
   ship 3.14. SpiderFoot is unmaintained (last commit Nov 2023) and installed
   with lifted version caps (`modules/40-frameworks.sh`); if it breaks, look for
   a maintained fork or drop it.
   `lib/ns_translate.py` forces `ARGOS_COMPUTE_TYPE=float32` on x86_64: the
   automatic int8 type gave repeated garbage on CI runners (Oct 2026). Retest
   with `auto` after CTranslate2 updates; float32 is slower.

## Future ideas (not started)

- **Local search of lawfully held breach data.** Discussed 2026-10-26 and
  parked by the maintainer. Only "bring your own data": import files the
  investigator lawfully holds (legal process, incident response, data shared
  by a CERT or partner) into a local SQLite FTS index, with source and legal
  basis recorded per import in audit.log, mode 600 storage, masked passwords,
  and deletion per dataset. Never bundle, download or automate access to
  breach dumps (forums, Telegram, torrents). An optional offline copy of HIBP
  Pwned Passwords (hashes only, official downloader, ~40-70 GB) is acceptable.

## Publishing

- Repo: https://github.com/det0xgravity/northstar-osint (public).
- Commit as `det0xgravity <170262817+det0xgravity@users.noreply.github.com>`
  (set in this repo's local git config), never a personal address.
