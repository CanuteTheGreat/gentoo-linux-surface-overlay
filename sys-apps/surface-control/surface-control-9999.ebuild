# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo git-r3

DESCRIPTION="Control various aspects of Microsoft Surface devices from the CLI"
HOMEPAGE="https://github.com/linux-surface/surface-control"
EGIT_REPO_URI="https://github.com/linux-surface/surface-control.git"

LICENSE="MIT"
SLOT="0"

RDEPEND="virtual/udev"
DEPEND="${RDEPEND}"

QA_FLAGS_IGNORED="usr/bin/surface"

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
	cargo_src_install
	dodoc README.md
}
