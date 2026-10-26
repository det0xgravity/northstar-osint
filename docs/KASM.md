# Running northstar on Proxmox with Kasm Workspaces

northstar-osint is designed to run well as a VM, either brokered in a browser by [Kasm Workspaces](https://kasmweb.com) or reached with any RDP client. The `vm` module (Linux) prepares the guest. This guide covers the rest.

## Recommended VM

| Setting | Value |
|---|---|
| OS | Debian 13 with GNOME |
| CPU | 4 vCPU, type `host` |
| RAM | 8 GB (16 GB if you use SpiderFoot heavily) |
| Disk | 60 GB+, VirtIO, discard on |
| Options | **QEMU Guest Agent: enabled** |
| Network | An isolated lab VLAN with no route to your home/office LAN |

Install with `./install.sh` from a terminal **inside the GNOME session** on the Proxmox console, then reboot.

## What the vm module does

- Detects the hypervisor and, on Proxmox (`kvm`), installs and starts **qemu-guest-agent**, which Kasm's Proxmox autoscaling needs, plus `spice-vdagent` for SPICE consoles.
- Installs **xrdp** and writes `~/.xsession` for your desktop: `gnome-session`, `startxfce4`, `mate-session` or `startplasma-x11`.
- Adds a **polkit rule** so RDP sessions don't ask for a password to "create a colour managed device".
- Adds a first-boot service that **regenerates SSH host keys** when they're missing, so clones never share keys.
- Installs **`ns-seal`** to `/usr/local/sbin`.

## Option A: one persistent VM (static server)

Use this when you want state to persist: logged-in sock puppets, browser profiles, ongoing cases.

1. In Kasm: **Admin → Infrastructure → Servers → Add**, with the VM's IP and connection type **RDP**, plus your Linux username and password.
2. Create a Workspace that points at that server.
3. **Log out of the Proxmox console first.** GNOME allows only one session per user, so an RDP login fails, or shows a black screen, while you're logged in on the console.

## Option B: disposable clones (Server Pool)

Use this for throwaway sessions where every launch starts clean.

Keep a **master** VM you maintain, and build templates from clones of it. Never seal the master itself.

```
master VM ──(full clone)──▶ clone ──(sudo ns-seal)──▶ shut down ──▶ convert to template
```

1. Update the master: `ns-update`, then reboot and test.
2. In Proxmox: **Clone → Full clone** of the master, with a new ID and a dated name (e.g. `northstar-tpl-2026-11`).
3. Boot the clone and run `sudo ns-seal`. It clears browser history and cookies (keeping settings and extensions), shell history, recent files, machine-id, SSH host keys and DHCP leases, optionally wipes case data, then shuts down.
4. Convert the clone to a template, in the resource pool your Kasm autoscale user can access.
5. Point your Kasm Server Pool's Proxmox provider at the new template name.

Keep the previous template until the new one is proven. Rolling back is then just pointing Kasm at the old name.

### Saving data from disposable sessions

Anything left inside a pool clone is destroyed when the session ends. Before closing, copy case folders out to shared storage (NFS, Nextcloud, a Git repo), or set `NS_DATA` to a mounted share in `~/.profile` on the master, so every clone writes its cases there.

## Over-the-browser tips

- Flameshot and clipboard tools use X11 under xrdp, so they work with no prompts.
- If the desktop is sluggish over RDP, turn off GNOME animations: `gsettings set org.gnome.desktop.interface enable-animations false`.
- Kasm's own clipboard and file transfer controls work alongside the in-VM clipboard.
