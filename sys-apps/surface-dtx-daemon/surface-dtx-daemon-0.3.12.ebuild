# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	aho-corasick@1.1.5
	anstream@1.0.0
	anstyle-parse@1.0.0
	anstyle-query@1.1.5
	anstyle-wincon@3.0.11
	anstyle@1.0.14
	anyhow@1.0.104
	bitflags@2.13.2
	bytes@1.12.1
	cfg-if@1.0.5
	cfg_aliases@0.2.2
	clap@4.6.7
	clap_builder@4.6.7
	clap_complete@4.6.11
	clap_lex@1.1.1
	colorchoice@1.0.5
	dbus-crossroads@0.5.3
	dbus-tokio@0.7.6
	dbus@0.9.12
	equivalent@1.0.3
	errno@0.3.14
	futures-channel@0.3.34
	futures-core@0.3.34
	futures-executor@0.3.34
	futures-io@0.3.34
	futures-macro@0.3.34
	futures-sink@0.3.34
	futures-task@0.3.34
	futures-util@0.3.34
	futures@0.3.34
	hashbrown@0.17.1
	indexmap@2.14.2
	is_terminal_polyfill@1.70.2
	lazy_static@1.5.1
	libc@0.2.191
	libdbus-sys@0.2.7
	log@0.4.34
	matchers@0.2.0
	memchr@2.8.3
	mio@1.2.4
	nix@0.31.3
	nu-ansi-term@0.50.3
	once_cell@1.21.4
	once_cell_polyfill@1.70.2
	pin-project-lite@0.2.17
	pkg-config@0.3.34
	proc-macro2@1.0.107
	quote@1.0.47
	regex-automata@0.4.18
	regex-syntax@0.8.11
	serde@1.0.229
	serde_core@1.0.229
	serde_derive@1.0.229
	serde_ignored@0.1.14
	serde_spanned@1.1.2
	sharded-slab@0.1.7
	signal-hook-registry@1.4.8
	slab@0.4.12
	smallvec@1.16.3
	socket2@0.6.5
	strsim@0.11.1
	syn@2.0.119
	syn@3.0.9
	thiserror-impl@2.0.21
	thiserror@2.0.21
	thread_local@1.1.10
	tokio-macros@2.7.2
	tokio@1.53.3
	toml@1.1.8+spec-1.1.0
	toml_datetime@1.1.2+spec-1.1.0
	toml_parser@1.1.5+spec-1.1.0
	toml_writer@1.1.3+spec-1.1.0
	tracing-attributes@0.1.31
	tracing-core@0.1.36
	tracing-log@0.2.0
	tracing-subscriber@0.3.23
	tracing@0.1.44
	unicode-ident@1.0.27
	utf8parse@0.2.2
	valuable@0.1.1
	wasi@0.11.1+wasi-snapshot-preview1
	windows-link@0.2.1
	windows-sys@0.61.2
	winnow@1.0.4
"

declare -A GIT_CRATES=(
	[sdtx-tokio]='https://github.com/linux-surface/libsurfacedtx;742d54e8d3c400e25e8fc7363bf6482b9ca7a7d2;libsurfacedtx-%commit%/sdtx-tokio'
	[sdtx]='https://github.com/linux-surface/libsurfacedtx;742d54e8d3c400e25e8fc7363bf6482b9ca7a7d2;libsurfacedtx-%commit%/sdtx'
)

inherit cargo systemd udev

DESCRIPTION="Surface Detach (DTX) daemon for Microsoft Surface Book devices"
HOMEPAGE="https://github.com/linux-surface/surface-dtx-daemon"
SRC_URI="
	https://github.com/linux-surface/surface-dtx-daemon/archive/refs/tags/v${PV}-1.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"
S="${WORKDIR}/${P}-1"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+=" MIT Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-libs/glib:2
	sys-apps/dbus
	virtual/udev
"
DEPEND="${RDEPEND}"

QA_FLAGS_IGNORED="usr/bin/surface-dtx-.*"

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
