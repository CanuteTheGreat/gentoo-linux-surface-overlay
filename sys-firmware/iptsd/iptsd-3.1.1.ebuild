# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson systemd udev

DESCRIPTION="Userspace daemon for Intel Precise Touch & Stylus (IPTS/ITHC) on Surface"
HOMEPAGE="https://github.com/linux-surface/iptsd"
SRC_URI="https://github.com/linux-surface/iptsd/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+tools"

DEPEND="
	dev-cpp/cli11
	dev-cpp/eigen:3
	dev-cpp/ms-gsl
	dev-libs/inih
	dev-libs/libfmt:=
	dev-libs/spdlog:=
	virtual/udev
"
RDEPEND="${DEPEND}"
BDEPEND="virtual/pkgconfig"

src_configure() {
	# upstream only installs its unit and udev rule when built against
	# systemd. They are installed by hand below for both init systems, so the
	# build never depends on systemd.
	local emesonargs=(
		-Dsample_config=true
		-Daccess_checks=true
		-Dservice_manager=
	)
	if use tools; then
		emesonargs+=( -Ddebug_tools=calibrate,dump,perf )
	else
		emesonargs+=( -Ddebug_tools= )
	fi
	meson_src_configure
}

src_install() {
	meson_src_install

	# systemd: template unit + the systemd half of the udev rule
	systemd_dounit "${BUILD_DIR}/etc/iptsd@.service"
	dobin etc/scripts/iptsd-systemd

	# OpenRC: multiplexed init script (iptsd, iptsd.hidrawN) + udev helper
	newinitd "${FILESDIR}/iptsd.initd" iptsd
	newconfd "${FILESDIR}/iptsd.confd" iptsd
	exeinto /usr/libexec
	doexe "${FILESDIR}/iptsd-openrc"

	# one rule file; picks systemd or OpenRC at runtime
	udev_dorules "${FILESDIR}/50-iptsd.rules"
}

pkg_postinst() {
	udev_reload
	if ! [[ -d /run/systemd/system ]]; then
		elog "OpenRC: enable the device manager service, it starts one"
		elog "iptsd.hidrawN instance per touch device (also on hotplug via udev):"
		elog "    rc-update add iptsd default && rc-service iptsd start"
	fi
}

pkg_postrm() {
	udev_reload
}
