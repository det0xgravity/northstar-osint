# Contributing to truebearing-osint

Thanks for helping. The project stays useful only if tools, links and install
methods keep up with the ecosystem, so small fixes are very welcome.

## Ground rules

- **Original work only.** Don't paste code, scripts, templates or assets from
  other OSINT courses, books or paid products. Linking to public resources is fine.
- **Official sources.** Install tools from their official package, PyPI, Go
  module or GitHub release. Never bundle third-party binaries in this repo.
- **No secrets.** Never commit API keys, cookies or personal data, including in
  example files or screenshots.
- **Lawful-use focus.** Tools must serve legitimate investigation. Stalkerware,
  credential stuffing and similar tools won't be accepted.

## Code style

- Bash must stay **Bash 3.2 compatible** (macOS): no associative arrays,
  `mapfile`, `${var,,}`/`${var^^}` or `&>>`.
- Use the helpers in `lib/common.sh` (`tb_apt`, `tb_brew`, `tb_pipx`, `tb_go`,
  `tb_git_venv`, `tb_gh_release`) instead of raw package commands.
- Module functions return non-zero on failure but don't `exit`: one broken tool
  must never stop the rest of the install.
- Menu tools use `lib/ui.sh` (`ui_*` dialogs, `tb_outdir`, `tb_run`,
  `tb_audit`, `tb_finish`) so output and audit logging stay consistent.
- Run `shellcheck -x -S warning` on everything you touch. CI runs it on every PR.

## Common contributions

### Add a tool to an existing module
Add one line to the module in `modules/`, for example:

```bash
tb_pipx newtool                                   # PyPI package == command
tb_pipx newtool some-package-name                 # command differs from package
tb_go github.com/owner/newtool/cmd/newtool@latest
tb_git_venv newtool https://github.com/owner/newtool newtool.py requirements.txt
```

Then add it to the module table in `docs/MODULES.md`.

### Add a bookmark
Edit `config/bookmarks.json` (keep the folder structure), then run
`./tools/tb-linkcheck config/bookmarks.json`.

### Add or improve a country
Each country is one JSON file in `config/countries/`. The format, and the checks to run, are in
[docs/COUNTRIES.md](docs/COUNTRIES.md#adding-or-improving-a-country). Local knowledge is the
most valuable contribution here: registries investigators in that country actually use.

### Add a Firefox extension
Add its addons.mozilla.org **slug** (the part of the URL after `/addon/`) to
`config/firefox-extensions.txt`. The GUID is looked up automatically.

### Add a new module
Create `modules/NN-name.sh`:

```bash
# shellcheck shell=bash
tb_register name "Short description" "linux macos" mod_name
mod_name() {
  local rc=0
  tb_pipx something || rc=1
  return $rc
}
```

## Testing

Run the offline test suite before opening a pull request. It needs no network or sudo, and runs on macOS's Bash 3.2 as well as Linux:

```bash
bash tests/run.sh
```

Menus can be driven without dialogs: set `TB_UI=script` and `TB_UI_ANSWERS` to a file with one answer per line (see the end of `lib/ui.sh`). Add a test to `tests/run.sh` for any new menu behaviour. CI runs it on every push, and a weekly workflow (`install.yml`) does real installs in Debian 13 and Ubuntu 24.04 containers on x86_64 and arm64.


Test on a fresh VM snapshot for each platform you changed. At minimum, check that
the install succeeds, that a second run is clean (idempotent), and that
`./install.sh --update --yes` works.

## Pull requests

Keep PRs focused, describe what you tested and on which platform, and update
`CHANGELOG.md` under an *Unreleased* heading.
