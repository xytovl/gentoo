# Copyright 1999-2018 Gentoo Authors
# Copyright 2017-2018 Sony Interactive Entertainment Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI=6
PYTHON_COMPAT=( python{2_7,3_{4,5,6}} )
DISTUTILS_OPTIONAL=1

inherit check-reqs bash-completion-r1 cmake-utils distutils-r1 flag-o-matic \
		multiprocessing python-r1 udev user readme.gentoo-r1 toolchain-funcs \
		systemd

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/ceph/ceph.git"
	SRC_URI=""
else
	SRC_URI="https://download.ceph.com/tarballs/${P}.tar.gz
		mgr-frontend? ( mirror://gentoo/${P}-frontend-node-modules.tar.xz )"
	KEYWORDS="~amd64 ~x86"
fi

DESCRIPTION="Ceph distributed filesystem"
HOMEPAGE="https://ceph.com/"

LICENSE="LGPL-2.1 CC-BY-SA-3.0 GPL-2 BSD Boost-1.0 MIT"
SLOT="0"

CPU_FLAGS_X86=(sse{,2,3,4_1,4_2} ssse3)

IUSE="babeltrace cephfs dpdk fuse jemalloc ldap lttng +mgr mgr-frontend"
IUSE+=" +radosgw +ssl static-libs +system-boost systemd +tcmalloc test"
IUSE+=" xfs zfs"
IUSE+=" $(printf "cpu_flags_x86_%s\n" ${CPU_FLAGS_X86[@]})"

# unbundling code commented out pending bugs 584056 and 584058
#>=dev-libs/jerasure-2.0.0-r1
#>=dev-libs/gf-complete-2.0.0
COMMON_DEPEND="
	virtual/libudev:=
	app-arch/bzip2:=[static-libs?]
	app-arch/lz4:=[static-libs?]
	app-arch/snappy:=[static-libs?]
	app-arch/zstd:=[static-libs?]
	app-misc/jq:=[static-libs?]
	dev-libs/crypto++:=[static-libs?]
	dev-libs/leveldb:=[snappy,static-libs?,tcmalloc?]
	dev-libs/libaio:=[static-libs?]
	dev-libs/libxml2:=[static-libs?]
	dev-libs/nss:=
	sys-auth/oath-toolkit:=
	sys-apps/keyutils:=[static-libs?]
	sys-apps/util-linux:=[static-libs?]
	sys-libs/zlib:=[static-libs?]
	babeltrace? ( dev-util/babeltrace )
	ldap? ( net-nds/openldap:=[static-libs?] )
	lttng? ( dev-util/lttng-ust:= )
	fuse? ( sys-fs/fuse:0=[static-libs?] )
	ssl? ( dev-libs/openssl:=[static-libs?] )
	xfs? ( sys-fs/xfsprogs:=[static-libs?] )
	zfs? ( sys-fs/zfs:=[static-libs?] )
	mgr? (
		<net-libs/nodejs-9.0
		>net-libs/nodejs-8.10
	)
	mgr-frontend? ( net-libs/nodejs[npm] )
	radosgw? (
		dev-libs/expat:=[static-libs?]
		dev-libs/openssl:=[static-libs?]
		net-misc/curl:=[curl_ssl_openssl,static-libs?]
	)
	system-boost? (
		>=dev-libs/boost-1.67:=[threads,context,python,static-libs?,${PYTHON_USEDEP}]
	)
	jemalloc? ( dev-libs/jemalloc:=[static-libs?] )
	!jemalloc? ( >=dev-util/google-perftools-2.4:=[static-libs?] )
	${PYTHON_DEPS}
	"
DEPEND="${COMMON_DEPEND}
	amd64? ( dev-lang/yasm )
	x86? ( dev-lang/yasm )
	app-arch/cpio
	dev-python/cython[${PYTHON_USEDEP}]
	dev-python/sphinx
	dev-util/cunit
	dev-util/gperf
	dev-util/valgrind
	sys-apps/which
	sys-devel/bc
	virtual/pkgconfig
	test? (
		dev-python/coverage[${PYTHON_USEDEP}]
		dev-python/tox[${PYTHON_USEDEP}]
		dev-python/virtualenv[${PYTHON_USEDEP}]
		sys-apps/grep[pcre]
		sys-fs/btrfs-progs
	)"
RDEPEND="${COMMON_DEPEND}
	net-misc/socat
	sys-apps/gptfdisk
	sys-block/parted
	sys-fs/cryptsetup
	sys-fs/lvm2
	!<sys-apps/openrc-0.26.3
	dev-python/bcrypt[${PYTHON_USEDEP}]
	dev-python/cherrypy[${PYTHON_USEDEP}]
	dev-python/flask[${PYTHON_USEDEP}]
	dev-python/jinja[${PYTHON_USEDEP}]
	dev-python/pecan[${PYTHON_USEDEP}]
	dev-python/prettytable[${PYTHON_USEDEP}]
	dev-python/pyopenssl[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	dev-python/werkzeug[${PYTHON_USEDEP}]
	"
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	|| ( $(python_gen_useflags 'python3*') )
	mgr-frontend? ( mgr || ( $(python_gen_useflags 'python2*') ) )
	?? ( jemalloc tcmalloc )
	"

# building npm stuff is currently broken
REQUIRED_USE="!mgr-frontend"

# the tests need root access
RESTRICT="test? ( userpriv )"

# distribution tarball does not include everything needed for tests
RESTRICT+=" test"

# false positives unless all USE flags are on
CMAKE_WARN_UNUSED_CLI="no"

STRIP_MASK="/usr/lib*/rados-classes/*"

UNBUNDLE_LIBS=(
	src/erasure-code/jerasure/jerasure
	src/erasure-code/jerasure/gf-complete
)

PATCHES=(
	"${FILESDIR}/ceph-12.2.0-use-provided-cpu-flag-values.patch"
	"${FILESDIR}/ceph-12.2.0-cflags.patch"
	"${FILESDIR}/ceph-12.2.4-boost-build-none-options.patch"
	"${FILESDIR}/ceph-13.2.0-cflags.patch"
	"${FILESDIR}/ceph-12.2.4-rocksdb-cflags.patch"
	"${FILESDIR}/ceph-13.2.0-mgr-python-version.patch"
	"${FILESDIR}/ceph-13.2.0-no-virtualenvs.patch"
	"${FILESDIR}/ceph-13.2.2-dont-install-sysvinit-script.patch"
)

check-reqs_export_vars() {
	if use amd64; then
		CHECKREQS_DISK_BUILD="12G"
		CHECKREQS_DISK_USR="460M"
	else
		CHECKREQS_DISK_BUILD="1400M"
		CHECKREQS_DISK_USR="450M"
	fi

	export CHECKREQS_DISK_BUILD CHECKREQS_DISK_USR
}

user_setup() {
	enewgroup ceph ${CEPH_GID}
	enewuser ceph "${CEPH_UID:--1}" -1 /var/lib/ceph ceph
}

pkg_pretend() {
	if use cephfs; then
		eerror "Cephfs support is broken in 13.2.2, please mask ${PF} if"
		eerror "you need cephfs support: "
		eerror " # echo '=${CATEGORY}/${PF}' >> /etc/portage/package.mask"
		eerror
		eerror "See https://bugs.gentoo.org/670592 for more information"
		die "CephFS support is currently broken"
	fi

	check-reqs_export_vars
	check-reqs_pkg_pretend
}

pkg_setup() {
	python_setup 'python3*'
	check-reqs_export_vars
	check-reqs_pkg_setup
	user_setup
}

src_prepare() {
	cmake-utils_src_prepare

	if use system-boost; then
		eapply "${FILESDIR}/ceph-13.2.0-boost-sonames.patch"
	fi

	sed -i -r "s:DESTINATION .+\\):DESTINATION $(get_bashcompdir)\\):" \
		src/bash_completion/CMakeLists.txt || die

	# remove tests that need root access
	rm src/test/cli/ceph-authtool/cap*.t || die

	#rm -rf "${UNBUNDLE_LIBS[@]}"
}

ceph_src_configure() {
	local flag
	local mycmakeargs=(
		-DWITH_BABELTRACE=$(usex babeltrace)
		-DWITH_CEPHFS=$(usex cephfs)
		-DWITH_DPDK=$(usex dpdk)
		-DWITH_FUSE=$(usex fuse)
		-DWITH_LTTNG=$(usex lttng)
		-DWITH_MGR=$(usex mgr)
		-DWITH_MGR_DASHBOARD_FRONTEND=$(usex mgr-frontend)
		-DWITH_OPENLDAP=$(usex ldap)
		-DWITH_RADOSGW=$(usex radosgw)
		-DWITH_SSL=$(usex ssl)
		-DWITH_SYSTEMD=$(usex systemd)
		-DWITH_TESTS=$(usex test)
		-DWITH_XFS=$(usex xfs)
		-DWITH_ZFS=$(usex zfs)
		-DENABLE_SHARED=$(usex static-libs '' 'yes' 'no')
		-DALLOCATOR=$(usex tcmalloc 'tcmalloc' "$(usex jemalloc 'jemalloc' 'libc')")
		-DWITH_SYSTEM_BOOST=$(usex system-boost)
		-DBOOST_J=$(makeopts_jobs)
		-DWITH_RDMA=no
		-DSYSTEMD_UNITDIR=$(systemd_get_systemunitdir)
		-DEPYTHON_VERSION="${EPYTHON#python}"
		-DCMAKE_INSTALL_DOCDIR="${EPREFIX}/usr/share/doc/${P}"
		-DCMAKE_INSTALL_SYSCONFDIR="${EPREFIX}/etc"
		-Wno-dev
	)
	if use amd64 || use x86; then
		for flag in ${CPU_FLAGS_X86[@]}; do
			mycmakeargs+=("$(usex cpu_flags_x86_${flag} "-DHAVE_INTEL_${flag^^}=1")")
		done
	fi

	rm -f "${BUILD_DIR:-${S}}/CMakeCache.txt"
	cmake-utils_src_configure

	# bug #630232
	sed -i "s:\"${T//:\\:}/${EPYTHON}/bin/python\":\"${PYTHON}\":" \
		"${BUILD_DIR:-${CMAKE_BUILD_DIR:-${S}}}"/include/acconfig.h \
		|| die "sed failed"
}

src_configure() {
	ceph_src_configure
}

python_compile() {
	local CMAKE_USE_DIR="${S}"
	ceph_src_configure

	rm -r "${BUILD_DIR}/lib/cython_modules" || die

	pushd "${BUILD_DIR}/src/pybind" >/dev/null || die
	emake VERBOSE=1 clean
	emake VERBOSE=1 all

	# python modules are only compiled with "make install" so we need to do this to
	# prevent doing a bunch of compilation in src_install
	DESTDIR="${T}" emake VERBOSE=1 install
	popd >/dev/null || die
}

src_compile() {
	if use mgr-frontend; then
		# npm likes trying to create /etc/npm
		addpredict /etc/npm

		# subshell to avoid polluting the environment
		(
			python_setup 'python2*'

			export CC="$(tc-getCC)" CXX="$(tc-getCXX)"

			set -e

			pushd src/pybind/mgr/dashboard/frontend >/dev/null

			npm install --offline --no-save --verbose --parseable \
				--no-rollback --no-progress --fetch-retries=0 \
				--nodedir="/usr/include/node" \
				--cache="${WORKDIR}/${P}-npm-cache" \
				--registry="http://npmjs.invalid" \
				--sass-binary-site="http://sass.invalid"

			# this tends to get installed to the system if it's still here
			rm -rf node_modules/node-sass/build

			popd >/dev/null

		) || die "failed to build node modules for mgr-frontend"
	fi

	cmake-utils_src_make VERBOSE=1 all

	# we have to do this here to prevent from building everything multiple times
	BUILD_DIR="${CMAKE_BUILD_DIR}" python_copy_sources
	python_foreach_impl python_compile
}

src_test() {
	make check || die "make check failed"
}

python_install() {
	local CMAKE_USE_DIR="${S}"
	pushd "${BUILD_DIR}/src/pybind" >/dev/null || die
	DESTDIR="${ED}" emake install
	popd >/dev/null || die
}

src_install() {
	cmake-utils_src_install
	python_foreach_impl python_install

	prune_libtool_files --all

	exeinto /usr/$(get_libdir)/ceph
	newexe "${CMAKE_BUILD_DIR}/bin/init-ceph" ceph_init.sh

	insinto /etc/logrotate.d/
	newins "${FILESDIR}"/ceph.logrotate-r2 ${PN}

	keepdir /var/lib/${PN}{,/tmp} /var/log/${PN}/stat

	fowners -R ceph:ceph /var/lib/ceph /var/log/ceph

	newinitd "${FILESDIR}/rbdmap.initd" rbdmap
	newinitd "${FILESDIR}/${PN}.initd-r9" ${PN}
	newconfd "${FILESDIR}/${PN}.confd-r4" ${PN}

	insinto /etc/sysctl.d
	newins "${FILESDIR}"/sysctld 90-${PN}.conf

	use tcmalloc && newenvd "${FILESDIR}"/envd-tcmalloc 99${PN}-tcmalloc

	# units aren't installed by the build system unless systemd is enabled
	# so no point installing these with the USE flag disabled
	if use systemd; then
		systemd_install_serviced "${FILESDIR}/ceph-mds_at.service.conf" \
			"ceph-mds@.service"

		systemd_install_serviced "${FILESDIR}/ceph-osd_at.service.conf" \
			"ceph-osd@.service"
	fi

	udev_dorules udev/*.rules

	readme.gentoo_create_doc

	python_setup 'python3*'

	# bug #630232
	sed -i -r "s:${T//:/\\:}/${EPYTHON}:/usr:" "${ED}"/usr/bin/ceph \
		|| die "sed failed"

	python_fix_shebang "${ED}"/usr/{,s}bin/

	# python_fix_shebang apparently is not idempotent
	sed -i -r  's:(/usr/lib/python-exec/python[0-9]\.[0-9]/python)[0-9]\.[0-9]:\1:' \
		"${ED}"/usr/{sbin/ceph-disk,bin/ceph-detect-init} || die "sed failed"
}

pkg_postinst() {
	readme.gentoo_print_elog
}
