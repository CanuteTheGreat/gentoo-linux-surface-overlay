# gentoo-linux-surface-overlay

Gentoo ebuilds for running Linux on Microsoft Surface devices, tracking the
[linux-surface](https://github.com/linux-surface/linux-surface) project.
Source of truth is `https://git.canutethegreat.com/CanuteTheGreat/gentoo-linux-surface-overlay`
(Forgejo); `https://github.com/CanuteTheGreat/gentoo-linux-surface-overlay` is a push mirror. Issues are welcome.

## Packages

| Package | What | Needed on |
|---|---|---|
| `sys-firmware/iptsd` | userspace daemon for the Intel touch/stylus processor (IPTS/ITHC), 3.x | Surface Pro 4 and newer, Book, Laptop, Go |
| `dev-libs/libwacom-surface` | upstream libwacom + linux-surface device data; replaces `dev-libs/libwacom` | same devices with a pen |
| `sys-apps/surface-control` | `surface` CLI (performance mode, DTX, ...) | Surface Aggregator devices (Pro 5+, Book 2+, Laptop) |
| `sys-apps/surface-dtx-daemon` | detach/attach handling for the Surface Book clipboard | Surface Book |

Removed (replaced elsewhere): `dev-cpp/CLI11` (use `dev-cpp/cli11` from `::gentoo`), `media-libs/libcamera` (`::gentoo`
has 0.7.0) and `sys-libs/hidrd` (unused since iptsd 3, no longer builds with GCC 15).
Each package keeps only its newest release plus an optional live `-9999`.

The Surface Pro 1/2 (2013) need none of these: touch and pen are plain HID in the mainline kernel.

## Use

    eselect repository add gentoo-linux-surface-overlay git https://github.com/CanuteTheGreat/gentoo-linux-surface-overlay.git
    emaint sync -r gentoo-linux-surface-overlay
    echo 'sys-firmware/iptsd ~amd64' >> /etc/portage/package.accept_keywords/surface   # all packages are ~amd64
    emerge -av sys-firmware/iptsd dev-libs/libwacom-surface sys-apps/surface-control

- Services: iptsd and surface-dtx-daemon install a systemd unit AND an OpenRC init script, on any system
  (no `systemd` USE flag).
  - `iptsd`: one udev rule serves both. systemd: `iptsd@<device>.service` is started by udev (as upstream).
    OpenRC: `rc-update add iptsd default`; the `iptsd` manager service starts an `iptsd.hidrawN` instance
    for every touch device present and udev adds/removes instances on hotplug. Options: `/etc/conf.d/iptsd`.
  - `surface-dtx-daemon`: systemd `systemctl enable --now surface-dtx-daemon`; OpenRC
    `rc-update add surface-dtx-daemon default` (`/etc/conf.d/surface-dtx-daemon`).
  - `surface-dtx-userd` (per user): systemd `systemctl --user enable --now surface-dtx-userd`; OpenRC either the
    XDG autostart entry (`/etc/xdg/autostart`, automatic in desktop sessions, does nothing under systemd) or the
    OpenRC user service (OpenRC >= 0.60): `rc-update --user add surface-dtx-userd default`. User services
    need the session bus at `$XDG_RUNTIME_DIR/bus` (or set `DBUS_SESSION_BUS_ADDRESS` in
    `~/.config/rc/conf.d/surface-dtx-userd`).
- Kernel: the linux-surface patched kernel is needed for most newer devices (see the linux-surface wiki).
  Include the keyboard/touch modules in the initramfs if the keyboard does not work during boot.

## Maintenance

A daily (06:17 UTC) Forgejo workflow (`.forgejo/workflows/update-check.yml`, nvchecker config in `.nvchecker/`) opens an
issue when upstream publishes a new release. Ebuilds are checked with `pkgcheck scan` and test-built in a
Gentoo stage3 container.
