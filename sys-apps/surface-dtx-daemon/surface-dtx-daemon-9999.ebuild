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

	# Cargo.toml pulls libsurfacedtx (sdtx, sdtx-tokio) from git by tag, which cannot
	# be fetched at (offline) install time: check it out with git-r3 and use path deps.
	local EGIT_REPO_URI="https://github.com/linux-surface/libsurfacedtx.git"
	local EGIT_CHECKOUT_DIR="${WORKDIR}/libsurfacedtx"
	git-r3_src_unpack
	local f
	while read -r f; do
		sed -i -E "s|^(sdtx(-tokio)?) = \{ git = \"[^\"]*libsurfacedtx\"[^}]*\}|\1 = { path = \"${WORKDIR}/libsurfacedtx/\1\" }|" "${f}" || die
	done < <(find "${S}" -name Cargo.toml)

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

	# OpenRC: system daemon
	newinitd "${FILESDIR}/surface-dtx-daemon.initd" surface-dtx-daemon
	newconfd "${FILESDIR}/surface-dtx-daemon.confd" surface-dtx-daemon

	# OpenRC: user daemon, either as an OpenRC user service (>= 0.60) ...
	exeinto /etc/user/init.d
	newexe "${FILESDIR}/surface-dtx-userd.initd" surface-dtx-userd
	# ... or as an XDG autostart entry (no-op under systemd)
	exeinto /usr/libexec
	doexe "${FILESDIR}/surface-dtx-userd-autostart"
	insinto /etc/xdg/autostart
	doins "${FILESDIR}/surface-dtx-userd.desktop"

	dodoc README.md
}

pkg_postinst() {
	udev_reload
	if ! [[ -d /run/systemd/system ]]; then
		elog "OpenRC: start the system daemon with"
		elog "    rc-update add surface-dtx-daemon default"
		elog "The per-user daemon surface-dtx-userd is started automatically by an"
		elog "XDG autostart entry (/etc/xdg/autostart) in desktop sessions. Alternatively"
		elog "use an OpenRC user service (OpenRC >= 0.60), as that user:"
		elog "    rc-update --user add surface-dtx-userd default"
		elog "(then disable the autostart entry, or the wrapper skips itself if an"
		elog "instance is already running)."
	fi
}

pkg_postrm() {
	udev_reload
}
