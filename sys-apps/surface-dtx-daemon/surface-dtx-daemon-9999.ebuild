# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo git-r3 systemd udev

DESCRIPTION="Surface Detach (DTX) daemon for Microsoft Surface Book devices"
HOMEPAGE="https://github.com/linux-surface/surface-dtx-daemon"
EGIT_REPO_URI="https://github.com/linux-surface/surface-dtx-daemon.git"

LICENSE="MIT"
SLOT="0"

RDEPEND="
	dev-libs/glib:2
	sys-apps/dbus
	virtual/udev
"
DEPEND="${RDEPEND}"

QA_FLAGS_IGNORED="usr/bin/surface-dtx-.*"

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

src_install() {
	cargo_src_install --path surface-dtx-daemon
	cargo_src_install --path surface-dtx-userd

	insinto /etc
	doins -r etc/dtx
	insinto /etc/dbus-1/system.d
	doins etc/dbus/org.surface.dtx.conf
	udev_dorules etc/udev/40-surface_dtx.rules
	systemd_dounit etc/systemd/surface-dtx-daemon.service
	systemd_douserunit etc/systemd/surface-dtx-userd.service
	dodoc README.md
}

pkg_postinst() {
	udev_reload
}

pkg_postrm() {
	udev_reload
}
