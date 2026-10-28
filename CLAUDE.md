# CLAUDE.md — truebearing-osint

Context for Claude Code sessions working on this repository.

## What this is

A modular, GPL-3.0-or-later OSINT workstation builder for Debian 13, Ubuntu 24.04/26.04,
Kali, Parrot and macOS on Apple Silicon. It's original work: never copy code,
templates or assets from OSINT books, courses or paid products, and don't add
references to them.

## Layout

- `install.sh`: entry point. Parses flags, detects the platform, sources every
  `modules/*.sh`, runs the selected modules through `tb_step`.
- `lib/common.sh`: installer helpers (`tb_apt`, `tb_brew`, `tb_cask`,
  `tb_flatpak`, `tb_pipx`, `tb_go`, `tb_go_ensure`, `tb_git_venv`,
  `tb_gh_release`, `tb_register`, platform detection).
- `lib/ui.sh`: runtime library for menu tools (`ui_*` dialogs via zenity or
  osascript, `tb_outdir`, `tb_run`, `tb_audit`, `tb_finish`, case handling).
- `lib/gen_policies.py`: builds Firefox/Brave policy JSON and a bookmarks export.
- `lib/tb_breach.py`, `lib/tb_darkweb.py`: engines for `tb-breach` and
  `tb-darkweb` (stdlib + curl; API keys read from `~/.config/truebearing/keys.env`).
- `lib/tb_vault.py`: the Obsidian case hub behind `tb-notes` (dashboards, result notes,
  findings, selectors, accounts, link chart, chronology, handover, the report's
  vault sections). Everything it renders from collected data goes through
  `cell()`/`code()`/`fence()`/`flink()`; never put raw web-sourced text in a link.
- `lib/tb_country.py`: engine for `tb-country` (reads the country packs, builds
  search links, phone analysis, `validate`).
- `lib/tb_guides.py`: renders `docs/*.md` to offline HTML in `~/TrueBearing/Guides`
  (desktop module; GitHub-style anchors via pandoc's `gfm` reader). Keep the
  guides' internal links working: `tests/run.sh` checks every anchor.
- `tools/tb-lan`: LAN isolation (nftables table `inet truebearing_lan`, service
  `truebearing-lan-block`, allow list in `/etc/truebearing/lan-allow`).
- Bookmarks may point to `{TB_DATA}/…` (local pages such as
  `assets/face-search.html`); `gen_policies.py --data` turns them into file:// links.
- `modules/NN-name.sh`: one module each; it registers with
  `tb_register name "desc" "linux macos" mod_name`.
- `tools/`: menu tools installed to `~/.local/share/truebearing/bin`.
- `config/bookmarks.json`, `config/firefox-extensions.txt`: data, not code.
- `config/countries/<cc>.json`: one country pack each (searches + bookmark
  folders). Format in `docs/COUNTRIES.md`.
- `assets/wallpaper/`: original desktop wallpaper (PNG) and its generator script.
- `docs/`: user documentation. Keep it in sync with behaviour changes.

## The rename (v0.41)

The project was northstar-osint until v0.41.0 (October 2026). Code that only
exists to move old installs across is marked "before v0.41" or "before the
rename": `tb_migrate_dirs`/`tb_migrate_legacy` (`lib/common.sh`), the LAN
hand-over in `modules/91-lan.sh`, old launchers/favourites/links in
`modules/70-desktop.sh`, `OLD_MARKS` and old snippet names in
`lib/tb_vault.py`, `NS_DATA` as a fallback for `TB_DATA`, and the `ns-…` /
`northstar` command shims written by `modules/00-core.sh`. Keep them until
the testers' VMs have updated; the shims can go first (a release or two),
the migration later. Don't rename the old names inside that code.

## Hard rules

- **Bash 3.2 compatible everywhere** (macOS ships 3.2): no `declare -A`,
  `mapfile`/`readarray`, `${var,,}`/`${var^^}`, `&>>`. Guard empty-array
  expansion under `set -u`.
- Module functions **return** non-zero on failure and never `exit`. One broken
  tool must not stop the install.
- Never remove Debian's `EXTERNALLY-MANAGED` file. Python tools go through pipx
  (`tb_pipx <command> [spec]`) or private venvs (`tb_git_venv`).
- Install only from official sources. Don't vendor third-party binaries.
- Menu tools must log through `tb_run`/`tb_audit`, and must never write secrets
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
python3 lib/tb_country.py validate
bash tests/run.sh                      # offline functional tests (also run in CI)
# after a real install: bash tests/e2e.sh   (CI: .github/workflows/e2e.yml, weekly/on demand)
./install.sh --list
```

CI (`.github/workflows/lint.yml`) runs the same checks.

## Status

First real install passed on 2026-10-26: Debian 13 GNOME, arm64, in a UTM
(QEMU) VM on Apple Silicon. The maintainer has since tested the username menu,
SpiderFoot, Country search, the GNOME tweaks, the wallpaper and the zsh setup
there. A tester's Ubuntu 26.04 x86_64 desktop install (Oct 2026, 0.37.0) failed
only on GHunt and ShadowFinder (Python 3.14 wheels, fixed in 0.37.2/0.38.0);
browsers (snap Firefox policies) and the Tor/Mullvad Flatpaks installed. The
e2e workflow covers Debian 13 and Ubuntu 24.04/26.04 containers on both arches.
Still untested: Proxmox/Kasm, Kali, Parrot, macOS. See CHANGELOG.md.

## Open work

1. **Amass v5 returns little without API keys.** A passive `amass enum` against
   a real domain (Oct 2026, v5.1.3) stored only the seed name. Check whether
   that's expected without `datasources.yaml` keys before relying on it. The
   engine listens on `:4000` on all interfaces and ignores `-dir` for storage.
2. **arm64 Tor Browser is the alpha.** `tb_tor_browser_tarball` switches to
   stable by itself once the release channel has `linux-aarch64`; then update
   the "alpha" notes in `docs/`. Mullvad Browser still has no arm64 Linux build.
   The signature check passes in the arm64 e2e containers (Oct 2026); still
   confirm "signature-verified" in the arm64 VM's install log.
3. **Bookmarks to check by hand.** `tb-linkcheck` can't verify sites that block
   scripts (403), including many in the country packs. Government sites in
   Australia, Indonesia, Thailand and Vietnam also drop connections from abroad
   (curl 000); their URLs were confirmed by search in Oct 2026, not by loading.
4. **Pinned workarounds to revisit.** theHarvester is pinned to 4.11.1 on
   Python < 3.14 (`modules/20-domain.sh`); drop the pin once supported distros
   ship 3.14. SpiderFoot is unmaintained (last commit Nov 2023) and installed
   with lifted version caps (`modules/40-frameworks.sh`); if it breaks, look for
   a maintained fork or drop it.
   On Python 3.14 (Ubuntu 26.04), GHunt comes from its main branch (2.3.4 caps
   Pillow < 11) and ShadowFinder goes in a private venv with current cartopy and
   timezonefinder (0.7.1 caps them): switch back to the PyPI releases once they
   lift those caps (`modules/10-username.sh`, `modules/35-geo.sh`).
   `lib/tb_translate.py` forces `ARGOS_COMPUTE_TYPE=float32` on x86_64: the
   automatic int8 type gave repeated garbage on CI runners (Oct 2026). Retest
   with `auto` after CTranslate2 updates; float32 is slower.

5. **Not yet tried in a real VM** (tests and containers only): LAN isolation
   (`tb-lan`; containers don't exercise boot-time loading or a real LAN),
   OnionShare receive and send, adult-site flags with the real Sherlock,
   Maigret and Blackbird, the face-search menu, and the case close, reopen and
   edit-intake flows.

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

- Repo: https://github.com/det0xgravity/truebearing-osint (public).
- Commit as `det0xgravity <170262817+det0xgravity@users.noreply.github.com>`
  (set in this repo's local git config), never a personal address.
