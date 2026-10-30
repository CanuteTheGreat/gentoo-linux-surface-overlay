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

- `iptsd` has a `systemd` USE flag: with it the per-device `iptsd@.service` and the udev rule are installed
  (needs systemd as init). Without it (OpenRC) only the daemon, presets and `/etc/iptsd.conf` are installed;
  start it yourself with `iptsd $(iptsd-find-hidraw)`.
- `surface-dtx-daemon`: `systemctl enable --now surface-dtx-daemon` and
  `systemctl --user enable --now surface-dtx-userd` on systemd; OpenRC users run the daemon from their own init script.
- Kernel: the linux-surface patched kernel is needed for most newer devices (see the linux-surface wiki).
  Include the keyboard/touch modules in the initramfs if the keyboard does not work during boot.

## Maintenance

A daily (06:17 UTC) Forgejo workflow (`.forgejo/workflows/update-check.yml`, nvchecker config in `.nvchecker/`) opens an
issue when upstream publishes a new release. Ebuilds are checked with `pkgcheck scan` and test-built in a
Gentoo stage3 container.
