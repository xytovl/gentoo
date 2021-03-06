# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools

DESCRIPTION="Font Library for enlightenment"
HOMEPAGE="https://www.enlightenment.org/"
SRC_URI="mirror://sourceforge/enlightenment/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 ia64 ppc sparc x86"
IUSE=""

DEPEND="media-libs/imlib"
RDEPEND="${DEPEND}"

DOCS=( AUTHORS ChangeLog HACKING NEWS README doc/fontinfo.README )

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	econf --sysconfdir="${EPREFIX}"/etc/fnlib
}
