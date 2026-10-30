# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

DESCRIPTION="Userspace daemon for Intel Precise Touch & Stylus (IPTS/ITHC) on Surface"
HOMEPAGE="https://github.com/linux-surface/iptsd"
SRC_URI="https://github.com/linux-surface/iptsd/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="systemd +tools"

DEPEND="
	dev-cpp/cli11
	dev-cpp/eigen:3
	dev-cpp/ms-gsl
	dev-libs/inih
	dev-libs/libfmt:=
	dev-libs/spdlog:=
	virtual/udev
	systemd? ( sys-apps/systemd )
"
RDEPEND="${DEPEND}"
BDEPEND="virtual/pkgconfig"

src_configure() {
	local emesonargs=(
		-Dsample_config=true
		-Daccess_checks=true
	)
	# upstream only knows systemd as service manager; without it only the
	# daemon binaries, presets and sample config are installed
	if use systemd; then
		emesonargs+=( -Dservice_manager=systemd )
	else
		emesonargs+=( -Dservice_manager= )
	fi
	if use tools; then
		emesonargs+=( -Ddebug_tools=calibrate,dump,perf )
	else
		emesonargs+=( -Ddebug_tools= )
	fi
	meson_src_configure
}

pkg_postinst() {
	if ! use systemd; then
		elog "Built without systemd: no service/udev integration was installed."
		elog "iptsd 3.x is started per touch device by iptsd-systemd (udev rule +"
		elog "iptsd@.service). On OpenRC run 'iptsd \$(iptsd-find-hidraw)' yourself,"
		elog "e.g. from a local.d script or your session start."
	fi
}
