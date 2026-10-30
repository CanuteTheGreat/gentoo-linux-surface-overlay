# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
inherit meson python-any-r1 udev

# linux-surface patch-set revision applied on top of upstream libwacom
SURFACE_REV="1"
SURFACE_P="libwacom-surface-${PV}-${SURFACE_REV}"

DESCRIPTION="Wacom tablet library with linux-surface patches for Microsoft Surface"
HOMEPAGE="
	https://github.com/linux-surface/libwacom-surface
	https://github.com/linuxwacom/libwacom
"
SRC_URI="
	https://github.com/linuxwacom/libwacom/releases/download/libwacom-${PV}/libwacom-${PV}.tar.xz
	https://github.com/linux-surface/libwacom-surface/archive/refs/tags/v${PV}-${SURFACE_REV}.tar.gz -> ${SURFACE_P}.tar.gz
"
S="${WORKDIR}/libwacom-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="doc test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-libs/glib-2.68:2
	dev-libs/libevdev
	dev-libs/libgudev:=
	!dev-libs/libwacom
"
DEPEND="${RDEPEND}"
BDEPEND="
	${PYTHON_DEPS}
	virtual/pkgconfig
	doc? ( app-text/doxygen )
	test? (
		$(python_gen_any_dep '
			dev-python/libevdev[${PYTHON_USEDEP}]
			dev-python/pyudev[${PYTHON_USEDEP}]
			dev-python/pytest[${PYTHON_USEDEP}]
		')
	)
"

python_check_deps() {
	use test || return 0
	python_has_version \
		"dev-python/libevdev[${PYTHON_USEDEP}]" \
		"dev-python/pyudev[${PYTHON_USEDEP}]" \
		"dev-python/pytest[${PYTHON_USEDEP}]"
}

src_prepare() {
	local patch
	for patch in "${WORKDIR}/${SURFACE_P}"/patches/v2/*.patch; do
		eapply "${patch}"
	done
	default
}

src_configure() {
	local emesonargs=(
		$(meson_feature doc documentation)
		$(meson_feature test tests)
		-Dudev-dir="$(get_udevdir)"
	)
	meson_src_configure
}

pkg_postinst() {
	udev_reload
}

pkg_postrm() {
	udev_reload
}
