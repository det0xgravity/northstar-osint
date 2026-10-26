# Troubleshooting

Everything the installer does is logged to `~/.config/northstar/install.log`. Re-running `./install.sh` is always safe: finished steps are skipped and failed ones are retried.

## Installer

**"Run as your normal user, not root or sudo."**
Run `./install.sh` without `sudo`. It asks for your password itself and uses sudo only where needed. If it ran as root, every per-user setting would land in root's profile instead of yours.

**A module reports FAILED.**
Look for `[!]` lines just above it, or search the log:
```bash
grep -n '\[!\]' ~/.config/northstar/install.log
```
Common causes are a temporary network error (re-run it), a package name that differs on your distribution (open an issue), or an upstream tool whose install method changed.

**`go install failed`**
Check `go version`. Current tools need Go 1.22+. northstar installs a current Go into `~/.local/share/northstar/go` automatically when the system Go is older, so open a new terminal to pick up the PATH change and re-run.

**`pipx failed: <tool>`**
Retry it by hand to see the actual error:
```bash
pipx install <package> --verbose
```

**Commands not found after install**
Open a new terminal. The PATH line is added to `~/.bashrc`, `~/.zshrc` or `~/.profile`. Or run `source ~/.bashrc`.

## Desktop and menus

**Dock icons or the Print Screen binding didn't appear**
These only apply when the installer runs inside a GNOME desktop session. Re-run from a terminal on the desktop, not over SSH:
```bash
./install.sh --only desktop,extras
```

**Launchers don't show in the app menu**
Log out and back in. The launchers are in `~/.local/share/applications/`.

**A menu opens and closes immediately**
Run it from a terminal (e.g. `ns-domain`) to see the error. If zenity is missing, re-run `./install.sh --only core`.

## Browsers

**Extensions or bookmarks don't appear in Firefox**
1. Fully quit Firefox (all windows), then start it again.
2. Open `about:policies`. It should show *Active* with ExtensionSettings and ManagedBookmarks.
3. If extensions are missing, the installer may have been offline when it looked up their IDs. Re-run `./install.sh --only browsers`.

**macOS: policies disappeared after Firefox updated**
Firefox updates replace the app bundle. Run `ns-update`, or `./install.sh --only browsers`.

**KeePassXC-Browser can't connect**
In KeePassXC: **Settings → Browser Integration → Enable**, tick Firefox, then click *Connect* in the extension.

## Tools

**gowitness produces no screenshots**
It needs Chromium (Linux) or Google Chrome (macOS). On macOS: `brew install --cask google-chrome`.

**theHarvester / h8mail / Shodan / Censys return little**
Many sources need API keys. Each tool's own documentation explains where its key file lives.

**amass leaves a process running**
Amass v5 starts a background engine (`amass engine`) the first time you run an enumeration, and it keeps running so later searches start faster. It listens on port 4000 **on all network interfaces**, so stop it when you're done, especially on a shared network: `pkill -f 'amass engine'`. Its database lives in `~/.config/amass` (Linux) or `~/Library/Application Support/amass` (macOS), not in the case folder.

**Maigret reports "Too many errors of type Bot protection"**
Some sites block automated checks from your IP address, so those sites show no result rather than a false "not found". Retry later, or from a different network or VPN exit.

**Instagram tools fail or rate-limit**
Use a sock-puppet login: `instaloader --login <puppet>`. For toutatis, use the `sessionid` cookie from that account.

**GHunt says it isn't logged in**
Run `ghunt login` once and follow its prompts.

## VM / Kasm

**No Tor Browser or Mullvad Browser in an arm64 VM**
That's expected: neither has a stable arm64 Linux build yet. See [INSTALL.md](INSTALL.md#running-in-a-vm-on-apple-silicon).

**The Activities overview keeps opening**
northstar turns off the top-left hot corner in VMs and the overview at login. To change either back: **Settings → Multitasking → Hot Corner**, or run `gnome-extensions disable no-overview@fthx`. The overview also opens when you press the Super (Windows/⌘) key. In UTM, that key goes to the VM while it has keyboard focus.

**Black screen when connecting over RDP**
You're probably still logged in on the Proxmox console. Log out there first, since GNOME allows one session per user. Also check that `~/.xsession` names your desktop session.

**"Authentication required to create a colour managed device"**
Re-run `./install.sh --only vm` to reinstall the polkit rule.

## Reporting a problem

Open an issue with your platform, the command you ran, and the relevant part of `install.log`. **Remove usernames, case names, targets and any API keys first.**
