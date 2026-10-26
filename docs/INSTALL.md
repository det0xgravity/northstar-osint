# Installation

## Requirements

| | |
|---|---|
| **Disk** | About 10 GB for a full install (browsers, Chromium, Go toolchain, Python venvs) |
| **RAM** | 4 GB minimum, 8 GB+ recommended (SpiderFoot and browsers are memory-hungry) |
| **Account** | A normal user with `sudo` rights. **Don't** run the installer as root. |
| **Network** | Unrestricted HTTPS to GitHub, PyPI, Go proxy, Flathub/Homebrew and addons.mozilla.org |

## Linux (Debian 13, Ubuntu 24.04, Kali, Parrot)

```bash
sudo apt install -y git
git clone https://github.com/det0xgravity/northstar-osint.git
cd northstar-osint
./install.sh
```

**Run it from a terminal inside your desktop session**, not over SSH. GNOME settings (dock favourites, the Print Screen binding, skipping the overview at login, and in VMs the hot corner) can only be applied inside a live desktop session. Over SSH, those steps are skipped with a note, and everything else installs normally. Re-run from the desktop later to apply them.

Per-distribution notes:

- **Debian 13**: Firefox ESR is the default browser; policies go to `/etc/firefox-esr/policies` and `/etc/firefox/policies`.
- **Ubuntu 24.04**: Firefox and Chromium are snaps. The policy file at `/etc/firefox/policies/policies.json` is read by the snap. If Firefox is missing, install it with `sudo snap install firefox`.
- **Kali**: most tools are already in Kali's repositories, but northstar installs its own current versions through pipx and Go so behaviour matches other platforms. The two don't conflict: northstar's copies live in `~/.local/share/northstar/bin` and `~/.local/bin`.
- **Parrot 6**: Parrot's Go is too old for current ProjectDiscovery tools, so northstar automatically installs the current Go release into `~/.local/share/northstar/go`.

## macOS (Apple Silicon)

1. Install the Xcode Command Line Tools: `xcode-select --install`
2. Install [Homebrew](https://brew.sh).
3. Then:

```bash
git clone https://github.com/det0xgravity/northstar-osint.git
cd northstar-osint
./install.sh
```

macOS differences:

- Menus use native macOS dialogs, and `~/Applications/Northstar.app` opens the main menu in Terminal.
- **Firefox policies** are written inside the app bundle (`Firefox.app/Contents/Resources/distribution/`). Firefox's self-updater can remove them, so run `ns-update` after a Firefox update.
- **Brave** managed bookmarks need an MDM configuration profile on macOS. Instead, import `~/Northstar/northstar-bookmarks.html` through Brave's *Bookmarks → Import*.
- **gowitness** needs Google Chrome for screenshots (`brew install --cask google-chrome`).
- **mat2** isn't available, so `ns-metadata` falls back to exiftool for cleaning.
- The `vm` module and `ns-seal` are Linux-only.

## Running in a VM on Apple Silicon

You can also install northstar in an arm64 Linux guest under UTM, Parallels Desktop or VMware Fusion. This keeps investigation browsing separate from your Mac. Use the **arm64 (aarch64)** installer for Debian 13 or Ubuntu 24.04. Kali and Parrot publish arm64 images too.

Install the guest from its ISO, log in to the desktop, then run `./install.sh` from a terminal inside it, the same as on any Linux machine. The `vm` module checks the hypervisor with `systemd-detect-virt` and installs the matching guest tools:

| Hypervisor | Detected as | What the `vm` module does |
|---|---|---|
| UTM (QEMU backend) | `qemu` | Installs `qemu-guest-agent` and `spice-vdagent` (shared clipboard, automatic resizing) |
| UTM (Apple Virtualization backend) | `apple` | Nothing extra: this backend needs no agent |
| VMware Fusion | `vmware` | Installs `open-vm-tools-desktop` |
| Parallels Desktop | `parallels` | Tells you to install Parallels Tools: **Actions → Install Parallels Tools** |
| Proxmox / KVM | `kvm` | Installs `qemu-guest-agent` and `spice-vdagent` (see [KASM.md](KASM.md)) |

xrdp, the SSH host-key service and `ns-seal` are set up in every case. If you don't plan to connect over RDP or clone the VM, you can skip the module: `./install.sh --skip vm`.

In UTM, choose the **QEMU** backend ("Virtualize", not "Apple Virtualization") if you want clipboard sharing with the Mac.

**Tor Browser and Mullvad Browser are skipped in arm64 Linux guests.** Flathub only builds them for x86_64, and the Tor Project's aarch64 Linux builds are still alpha releases, which it doesn't recommend if you need strong anonymity. The installer prints a note and carries on. Until stable arm64 builds ship, you can:

- run them on the Mac host instead, where `./install.sh --only browsers` installs both from Homebrew, or
- download the Tor Browser alpha for Linux (aarch64) from [torproject.org](https://www.torproject.org/download/alpha/) at your own risk.

Firefox, Brave and every other module work normally on arm64.

## Options

```
./install.sh --list                 List modules for this platform
./install.sh --only a,b             Install only these modules (core always runs)
./install.sh --skip a,b             Install everything except these
./install.sh --update               Upgrade tools that are already installed
./install.sh --yes                  Don't prompt
```

The installer records the modules you chose **not** to install in `~/.config/northstar/skipped`. `ns-update` upgrades everything else, so a module added in a new release is installed automatically. To install a module you skipped earlier, run `./install.sh --only <module>`. To stop installing one, run `./install.sh --skip <module>`.

## Where things go

| Path | Contents |
|---|---|
| `~/.local/share/northstar/bin` | Menu tools and Go/binary tools (also linked into `~/.local/bin`) |
| `~/.local/share/northstar/venvs` | Private Python environments (SpiderFoot, recon-ng, blackbird, phone analysis) |
| `~/.local/share/northstar/src` | Git checkouts of tools installed from source |
| `~/.local/share/northstar/go` | Go toolchain, only if the system Go was too old |
| `~/.local/pipx`, `~/.local/bin` | pipx-managed tools |
| `~/.config/northstar` | Active case, installed module list, install log |
| `~/Northstar/Cases` | Your investigation output and audit logs |
| `~/Northstar/northstar-bookmarks.html` | Bookmarks export for importing into other browsers |
| `/etc/firefox*/policies/policies.json` | Firefox policy (Linux) |
| `/etc/brave/policies/managed/northstar.json` | Brave policy (Linux) |

## Customising

- **Your own bookmarks**: create `~/.config/northstar/bookmarks.local.json` with the same structure as `config/bookmarks.json` (a list of folders). It's merged into the managed folder on the next run, and repository updates never overwrite it.
- **Extensions**: list extra Firefox add-ons in `~/.config/northstar/firefox-extensions.local.txt`, one addons.mozilla.org slug per line (the part of the add-on's URL after `/addon/`). They're added to northstar's own list on the next run. Apply them now with `./install.sh --only browsers`.

Don't edit files inside your northstar-osint checkout. `ns-update` downloads new versions with `git pull`, which fails if repository files were changed by hand. Your files in `~/.config/northstar/` are never touched by updates.
- **Output location**: set `NS_DATA=/path` in your shell profile to keep cases somewhere other than `~/Northstar`.

## Updating

```bash
ns-update
```

This pulls the latest northstar-osint, upgrades pipx tools, reinstalls Go tools at their latest versions, pulls source checkouts, upgrades system packages and re-applies browser policies.

## Uninstalling

```bash
pipx uninstall-all                                   # removes ALL pipx tools, including non-northstar ones
rm -rf ~/.local/share/northstar ~/.config/northstar
rm -f ~/.local/bin/northstar ~/.local/bin/ns-*
rm -f ~/.local/share/applications/northstar.desktop ~/.local/share/applications/ns-*.desktop
sudo rm -f /etc/firefox/policies/policies.json /etc/firefox-esr/policies/policies.json \
           /etc/brave/policies/managed/northstar.json /usr/local/sbin/ns-seal
# Remove the line tagged "northstar-osint" from ~/.bashrc / ~/.zshrc / ~/.profile
```

Your case data in `~/Northstar` is left alone. Delete it yourself if you mean to.
