# Troubleshooting

Everything the installer does is logged to `~/.config/truebearing/install.log`. Re-running `./install.sh` is always safe: finished steps are skipped and failed ones are retried.


## The install looks stuck

Each module header shows where you are (`==> [5/18] ████░░░░ geo: …`), and every long step has a status line underneath that updates each second:

```
    / [5/18] PyTorch (CPU)  03:12  ███████████░░░░░░░░░  56%  torch (104.1 MB)
```

If the spinner turns and the time counts up, it's working: PyTorch (geo, translate), Flatpak runtimes and the Go toolchain are large first downloads. If the time stops, check `tail -f ~/.config/truebearing/install.log` in another terminal; the full output of every step is there. Status lines only appear in a terminal; piped or in CI, the log has everything.

## Installer

**"Run as your normal user, not root or sudo."**
Run `./install.sh` without `sudo`. It asks for your password itself and uses sudo only where needed. If it ran as root, every per-user setting would land in root's profile instead of yours.

**A module reports FAILED.**
Look for `[!]` lines just above it, or search the log:
```bash
grep -n '\[!\]' ~/.config/truebearing/install.log
```
Common causes are a temporary network error (re-run it), a package name that differs on your distribution (open an issue), or an upstream tool whose install method changed.

**`go install failed`**
Check `go version`. Current tools need Go 1.22+. True Bearing installs a current Go into `~/.local/share/truebearing/go` automatically when the system Go is older, so open a new terminal to pick up the PATH change and re-run.

**`pipx failed: <tool>`**
Retry it by hand to see the actual error:
```bash
pipx install <package> --verbose
```

**Commands not found after install**
Open a new terminal. The PATH line is added to `~/.bashrc`, `~/.zshrc` or `~/.profile`. Or run `source ~/.bashrc`.

## Desktop and menus

**Dock icons or the Print Screen and Super+Shift+S bindings didn't appear**
These only apply when the installer runs inside a GNOME desktop session. Re-run from a terminal on the desktop, not over SSH:
```bash
./install.sh --only desktop,extras
```

**Launchers don't show in the app menu**
Log out and back in. The launchers are in `~/.local/share/applications/`.

**The guides aren't on the desktop**
Log out and back in once: GNOME shows desktop icons only after the Desktop Icons NG extension the installer enables has loaded. The guides themselves are in `~/TrueBearing/Guides` (open `index.html`), and under **Guides** in the main menu. If that folder is empty, pandoc is missing or failed: run `./install.sh --only desktop` and check its output.

**A menu opens and closes immediately**
Run it from a terminal (e.g. `tb-domain`) to see the error. If zenity is missing, re-run `./install.sh --only core`.

## Browsers

**Extensions or bookmarks don't appear in Firefox**
1. Fully quit Firefox (all windows), then start it again.
2. Open `about:policies`. It should show *Active* with ExtensionSettings and ManagedBookmarks.
3. If extensions are missing, the installer may have been offline when it looked up their IDs. Re-run `./install.sh --only browsers`.

**macOS: policies disappeared after Firefox updated**
Firefox updates replace the app bundle. Run `tb-update`, or `./install.sh --only browsers`.

**KeePassXC-Browser can't connect**
In KeePassXC: **Settings → Browser Integration → Enable**, tick Firefox, then click *Connect* in the extension.

## Tools

**gowitness produces no screenshots**
It needs Chromium (Linux) or Google Chrome (macOS). On macOS: `brew install --cask google-chrome`.

**theHarvester / Shodan / Censys return little**
Many sources need API keys. Each tool's own documentation explains where its key file lives.

**amass leaves a process running**
Amass v5 starts a background engine (`amass engine`) the first time you run an enumeration, and it keeps running so later searches start faster. It listens on port 4000 **on all network interfaces**, so stop it when you're done, especially on a shared network: `pkill -f 'amass engine'`. Its database lives in `~/.config/amass` (Linux) or `~/Library/Application Support/amass` (macOS), not in the case folder.

**Maigret reports "Too many errors of type Bot protection"**
Some sites block automated checks from your IP address, so those sites show no result rather than a false "not found". Retry later, or from a different network or VPN exit.

**Instagram tools fail or rate-limit**
Use a sock-puppet login: `instaloader --login <puppet>`. For toutatis, use the `sessionid` cookie from that account.

**GHunt says it isn't logged in**
Run `ghunt login` once and follow its prompts.

**GHunt or ShadowFinder failed with "headers or library files could not be found for jpeg" or "ffi.h: No such file"**
That was Ubuntu 26.04 (Python 3.14) before v0.37.2: their last releases asked for library versions that have no Python 3.14 builds. Run `tb-update`: on Python 3.14 True Bearing now installs GHunt from its main branch and ShadowFinder with current libraries.

**OnionShare says it can't find or connect to Tor**
The menu's OnionShare options use the system Tor (`tb-darkweb` → **Check Tor connection** starts it). If `onionshare-cli` is missing, run `./install.sh --only darkweb`. On macOS use **Open the OnionShare app** instead.

**Received files (OnionShare)**
They're in the case under `received/`, with their SHA-256 in `received.txt` and a check of every file in `triage.txt`. Treat them as hostile even when triage finds nothing: open documents only in the VM, never run programs or enable macros, and record what you rely on as an exhibit.

**Triage says "ClamAV couldn't scan it"**
ClamAV's signatures haven't downloaded yet (about 200 MB, in the background after install). Check with `systemctl status clamav-freshclam`, or fetch them now: `sudo systemctl stop clamav-freshclam && sudo freshclam && sudo systemctl start clamav-freshclam`.

## VM / Kasm

**Something on my network stopped working after an update (NAS, printer, file share, local apt mirror)**
LAN isolation (`tb-lan`) is on: since v0.38.0 it's turned on in VMs, and it blocks connections from the VM to private networks. Check with `tb-lan status`. Allow what you need with `tb-lan allow 192.168.1.20` (an address or a network such as `192.168.1.0/24`), or turn it off with `tb-lan off`; updates won't turn it back on. Connections made **to** the VM (RDP from Kasm, SSH) aren't affected.

**No Mullvad Browser in an arm64 VM, and Tor Browser says "alpha"**
That's expected. Mullvad Browser has no arm64 Linux build, and Tor Browser's only arm64 Linux builds are alphas for now. True Bearing switches to stable automatically once one exists. See [BREACH-DARKWEB.md](BREACH-DARKWEB.md#tor-browser-on-arm64-vms-on-apple-silicon).

**Tor Browser "signature did NOT verify"**
The download didn't match the Tor Project's signing key, so nothing was installed. Usually it's a broken or intercepted download: run `tb-update` again. If it keeps happening, don't install Tor Browser on that network.

**tb-darkweb says Tor isn't reachable**
On Linux: `sudo systemctl start tor`, then `systemctl status tor`. On macOS: `brew services start tor`. Some networks block Tor; Tor Browser's connection settings can use bridges in that case.

**A breach source shows "rate limit reached" or "key rejected"**
Free services limit how often you can search (XposedOrNot about 25 an hour; ransomware.live one a minute). Wait and retry. "Key rejected" means the API key is wrong or has expired: update it in **API keys**.

**A menu seems to stop after "Results saved to:"**
Its next dialog has probably opened behind another window: GNOME doesn't let a new window jump in front of the one you're using. Press Alt+Tab to find it. Since v0.4.3, tools started from the main menu no longer open the file manager by themselves, so this mostly happens after *Image analysis*, which opens the folder so you can drag the image into the search pages. Use **Open latest results** in the main menu to see what a search produced.

**The Activities overview keeps opening**
True Bearing stops the overview opening at login, and in VMs also turns off the two usual triggers: the top-left hot corner, and pressing the Super key on its own. The Super trigger matters because the host's ⌘ or Windows key reaches the VM as Super whenever you switch apps. To check or apply these by hand:

```bash
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.mutter overlay-key ''
```

In VMs it also switches GNOME to **one fixed workspace**. With GNOME's default dynamic workspaces, a search that sends tabs to a browser window on another workspace makes the screen slide over to it. The "pill and dot" at the top left is the workspace indicator. To set this by hand:

```bash
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 1
```

To undo them: **Settings → Multitasking** (hot corner and workspaces), `gsettings reset org.gnome.mutter overlay-key`, and `gnome-extensions disable no-overview@fthx`. You can still open the overview with the dots at the top left, or Super+S.

**Clicking Flameshot does nothing**
Flameshot runs in standby as an icon in the top bar, and GNOME needs the AppIndicator extension to show tray icons. True Bearing enables it; log out and back in after `tb-update` to see the icon. Flameshot also starts at login. Click its icon, or press Print Screen (or Super+Shift+S: Cmd+Shift+S on a Mac keyboard), to capture. If it ever stops responding: `pkill flameshot`, then start it again.

**Flameshot says "Unable to capture screen"**
On Wayland, GNOME only lets Flameshot capture once it has permission, and it never asks when Flameshot runs from the tray or a shortcut. The extras module grants it; on an older install run `tb-update --only extras`, or:
```bash
flatpak permission-set screenshot screenshot org.flameshot.Flameshot yes
flatpak permission-set screenshot screenshot flameshot yes
```

**Cmd+Shift+S says "Screenshot aborted"**
Releasing Cmd (Super) during the capture cancels it. The shortcut waits half a second for that; on an older install run `tb-update --only extras`.

**The prompt shows squares or question marks instead of icons**
The terminal isn't using the MesloLGS NF font. Run `tb-update` from inside the desktop session, or set the font by hand in your terminal's preferences: **MesloLGS NF**, size 11. Then open a new terminal.

**The terminal still opens bash**
The default shell changes from your next login: log out and back in. To check: `getent passwd $USER` should end in `/usr/bin/zsh`.

**Black screen when connecting over RDP**
You're probably still logged in on the Proxmox console. Log out there first, since GNOME allows one session per user. Also check that `~/.xsession` names your desktop session.

**"Authentication required to create a colour managed device"**
Re-run `./install.sh --only vm` to reinstall the polkit rule.

## Reporting a problem

Open an issue with your platform, the command you ran, and the relevant part of `install.log`. **Remove usernames, case names, targets and any API keys first.**
