# SYSTEM_PKGS is "install enough to get a TV picture"
SYSTEM_PKGS = neutrino-pkg minimal-system-pkgs
# packages which don't get pulled in by dependencies
SYSTEM_OPKGS =

# additional stuff which is useful on most systems
SYSTEM_PKGS  += e2fsprogs
SYSTEM_OPKGS += e2fsprogs

glibc-pkg: $(TARGETPREFIX)/sbin/ldconfig
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)
	set -e; cd $(PKGPREFIX); \
		mkdir lib sbin etc; \
		if test -e $(CROSS_DIR)/$(TARGET)/sys-root/lib; then \
			cp -a $(CROSS_DIR)/$(TARGET)/sys-root/lib/*.so* lib/; \
		else \
			cp -a $(CROSS_DIR)/$(TARGET)/lib/*.so* lib/; \
		fi; \
		if test -e $(CROSS_DIR)/$(TARGET)/sys-root/usr/lib/libstdc++.so; then \
			cp -a $(CROSS_DIR)/$(TARGET)/sys-root/usr/lib/libstdc++.s*[!y] lib/; \
		fi; \
		(cp -a $(TARGETPREFIX)/sbin/ldconfig sbin/||true);  \
		rm -fv lib/libnss_hesiod* lib/libnss_nis* lib/libnss_compat* \
		   lib/libmudflap* lib/libc.so lib/libpthread.so \
		   lib/libcidn* lib/*.so_orig lib/*.py; \
		find lib -name '*.so' -type l -print0 | xargs -0 --no-run-if-empty rm -v
	touch $(PKGPREFIX)/etc/ld.so.conf
	$(REMOVE)/glibc-control
	cp -a $(CONTROL_DIR)/glibc $(BUILD_TMP)/glibc-control
	# two packages are built, so we are not using the PKG_VER feature of opkg.sh
	VER=`cd $(PKGPREFIX)/lib; echo ld-*.so` && VER=$${VER#ld-} && VER=$${VER%.so} && \
		sed -i "s/@VER@/$$VER/" $(BUILD_TMP)/glibc-control/control
	# lame attempt at "auto-provides" for glibc...
	PROV=`opkg-find-provides.sh $(PKGPREFIX)` && \
		sed -i "s/@PROV@/$$PROV/" $(BUILD_TMP)/glibc-control/control
	$(OPKG_SH) $(BUILD_TMP)/glibc-control
	sed -i	-e 's/^Package: glibc$$/Package: glibc-debug/' \
		-e 's/^Description:.*/Description: The GNU C library (unstripped)/' \
		 $(BUILD_TMP)/glibc-control/control
	DONT_STRIP=1 $(OPKG_SH) $(BUILD_TMP)/glibc-control
	rm -rf $(PKGPREFIX) $(BUILD_TMP)/glibc-control

ifeq ($(PLATFORM), coolstream)
cs-drivers-pkg:
	# we have two directories packed, the newer one determines the package version
	rm -rf $(BUILD_TMP)/tmp-ctrl
	cp -a $(CONTROL_DIR)/cs-drivers $(BUILD_TMP)/tmp-ctrl
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib/modules/$(UNCOOL_KVER_FULL)
	mkdir    $(PKGPREFIX)/lib/firmware
ifneq ($(UNCOOL_SOURCE), git)
	opkg-controlver-from-svn.sh $(BUILD_TMP)/tmp-ctrl/control \
		$(SOURCE_DIR)/svn/COOLSTREAM/2.6.26.8-nevis $(SOURCE_DIR)/svn/THIRDPARTY/lib/firmware
	opkg-chksvn.sh $(BUILD_TMP)/tmp-ctrl $(SOURCE_DIR)/svn/COOLSTREAM/2.6.26.8-nevis || \
	opkg-chksvn.sh $(BUILD_TMP)/tmp-ctrl $(SOURCE_DIR)/svn/THIRDPARTY/lib/firmware
	cp -a $(SOURCE_DIR)/svn/COOLSTREAM/2.6.26.8-nevis/* $(PKGPREFIX)/lib/modules/2.6.26.8-nevis
	cp -a $(SOURCE_DIR)/svn/THIRDPARTY/lib/firmware/*   $(PKGPREFIX)/lib/firmware
else
	set -e; cd $(UNCOOL_DRVBASE); \
		sed -i 's/^Package:.*$$/Package: cs-drivers_$(subst .,_,$(UNCOOL_KVER))/' \
			$(BUILD_TMP)/tmp-ctrl/control; \
		opkg-gitdescribe.sh $(BUILD_TMP)/tmp-ctrl/control . drivers/$(UNCOOL_KVER_FULL) firmware; \
		cp -a drivers/$(UNCOOL_KVER_FULL) $(PKGPREFIX)/lib/modules/$(UNCOOL_KVER_FULL)/extra; \
		cp -a firmware/*                  $(PKGPREFIX)/lib/firmware
	rm $(PKGPREFIX)/lib/modules/$(UNCOOL_KVER_FULL)/extra/cifs.ko # we build our own...
endif
	mkdir -p $(PKGPREFIX)/etc/init.d
	cp -a skel-root/$(PLATFORM)/etc/init.d/*loadmodules $(PKGPREFIX)/etc/init.d
	DONT_STRIP=1 $(OPKG_SH) $(BUILD_TMP)/tmp-ctrl
	rm -rf $(PKGPREFIX) $(BUILD_TMP)/tmp-ctrl

cs-libs-pkg: $(UNCOOL_LIBS)
	rm -rf $(BUILD_TMP)/tmp-ctrl
	cp -a $(CONTROL_DIR)/cs-libs $(BUILD_TMP)/tmp-ctrl
ifneq ($(UNCOOL_SOURCE), git)
	opkg-controlver-from-svn.sh $(BUILD_TMP)/tmp-ctrl/control \
		$(SVN_TP_LIBS)/libnxp/libnxp.so \
		$(SVN_TP_LIBS)/libcs/libcoolstream.so \
		$(SVN_TP_LIBS)/libcs/libcoolstream-mt.so
	opkg-chksvn.sh $(BUILD_TMP)/tmp-ctrl $(SVN_TP_LIBS)/libnxp/libnxp.so || \
	opkg-chksvn.sh $(BUILD_TMP)/tmp-ctrl $(SVN_TP_LIBS)/libcs/libcoolstream.so || \
	opkg-chksvn.sh $(BUILD_TMP)/tmp-ctrl $(SVN_TP_LIBS)/libcs/libcoolstream-mt.so
else
	opkg-gitdescribe.sh $(BUILD_TMP)/tmp-ctrl/control $(UNCOOL_DRVBASE)/libs
endif
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(UNCOOL_LIBS) $(PKGPREFIX)/lib
	PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(BUILD_TMP)/tmp-ctrl
	rm -rf $(PKGPREFIX) $(BUILD_TMP)/tmp-ctrl

usb-driver-pkg: cskernel
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/kernel/drivers/usb
	set -e; cd $(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/kernel/drivers/usb; \
		cp -a $(TARGETPREFIX)/mymodules/lib/modules/$(KVERSION_FULL)/kernel/drivers/usb/* .
	depmod -n -ae -E $(K_OBJ)/Module.symvers -b $(PKGPREFIX) $(KVERSION_FULL) 2>&1 >/dev/null \
		| grep WARNING; test $$? != 0 # invert return code
	DONT_STRIP=1 PKG_VER=$(KVERSION) $(OPKG_SH) $(CONTROL_DIR)/usb-drivers
	rm -rf $(PKGPREFIX)

addon-drivers-pkg: cskernel |$(HOSTPREFIX)/bin/opkg-module-deps.sh
	$(REMOVE)/addon-drivers $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/kernel/
	set -e; cd $(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/kernel/; \
		cp -a $(SOURCE_MODULE)/kernel/* ./; \
		rm -fr drivers/usb fs/autofs4 drivers/media/dvb # is in usb-driver-pkg and autofs
		# self compiled dvb-core does not work with the cs-drivers -- probably their version
		# has some unknown patch...
	depmod -n -ae -E $(K_OBJ)/Module.symvers -b $(PKGPREFIX) $(KVERSION_FULL) 2>&1 >/dev/null \
		| grep WARNING; test $$? != 0 # invert return code
	cp -a $(CONTROL_DIR)/addon-drivers $(BUILD_TMP)
	sed -i 's/^Package:.*$$/Package: addon-drivers_$(subst .,_,$(UNCOOL_KVER))/' \
		$(BUILD_TMP)/addon-drivers/control; \
	opkg-module-deps.sh $(PKGPREFIX) $(BUILD_TMP)/addon-drivers/control
	sed -i 's/^Provides: /Provides: addon-drivers, /' $(BUILD_TMP)/addon-drivers/control
	DONT_STRIP=1 PKG_VER=$(KVERSION) $(OPKG_SH) $(BUILD_TMP)/addon-drivers
	$(REMOVE)/addon-drivers $(PKGPREFIX)

PHONY += cs-drivers-pkg cs-libs-pkg
SYSTEM_PKGS += cs-libs-pkg cs-drivers-pkg
endif
ifeq ($(PLATFORM), tripledragon)
td-module-pkg:
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	make $(PKGPREFIX)/lib/modules/2.6.12
	mkdir -p $(PKGPREFIX)/etc/init.d
	cp -a skel-root/$(PLATFORM)/etc/init.d/*loadmodules $(PKGPREFIX)/etc/init.d
	DONT_STRIP=1 $(OPKG_SH) $(CONTROL_DIR)/td-drivers
	rm -rf $(PKGPREFIX)

td-directfb-pkg:
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/etc $(PKGPREFIX)/lib
	make $(PKGPREFIX)/stb/lib/directfb-0.9.24
	cp -av $(TD_SVN)/ARMAS/filesystem-skeleton/stb/lib/libdirect* $(PKGPREFIX)/lib/
	cp -av $(TD_SVN)/ARMAS/filesystem-skeleton/stb/lib/libfusion* $(PKGPREFIX)/lib/
	cp -a $(SCRIPTS)/directfbrc-td $(PKGPREFIX)/etc/directfbrc
	DONT_STRIP=1 $(OPKG_SH) $(CONTROL_DIR)/td-directfb
	rm -rf $(PKGPREFIX)

td-dvb-wrapper-pkg: $(TARGET_MODULE)/extra/td-dvb-frontend.ko
	rm -rf $(PKGPREFIX)
	install -m 644 -D $(TARGET_MODULE)/extra/td-dvb-frontend.ko \
		$(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/extra/td-dvb-frontend.ko
	DONT_STRIP=1 PKG_VER=1 $(OPKG_SH) $(CONTROL_DIR)/td-dvb-wrapper
	rm -rf $(PKGPREFIX)

addon-drivers-pkg: tdkernel |$(HOSTPREFIX)/bin/opkg-module-deps.sh
	$(REMOVE)/addon-drivers $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/kernel/
	set -e; cd $(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/kernel/; \
		cp -a $(SOURCE_MODULE)/kernel/* ./; \
		rm -fr drivers/usb/host drivers/usb/storage fs/autofs4 # is in td-module-pkg and autofs
	depmod -n -ae -F $(BUILD_TMP)/linux-2.6.12/System.map -b $(PKGPREFIX) $(KVERSION_FULL) 2>&1 >/dev/null \
		| grep -v "could not open" \
		| grep WARNING; test $$? != 0 # invert return code
	cp -a $(CONTROL_DIR)/addon-drivers $(BUILD_TMP)
	opkg-module-deps.sh $(PKGPREFIX) $(BUILD_TMP)/addon-drivers/control
	DONT_STRIP=1 PKG_VER=$(KVERSION_FULL) $(OPKG_SH) $(BUILD_TMP)/addon-drivers
	$(REMOVE)/addon-drivers $(PKGPREFIX)

PHONY += td-module-pkg td-directfb-pkg
SYSTEM_PKGS += td-module-pkg td-directfb-pkg td-dvb-wrapper-pkg addon-drivers-pkg
endif
ifeq ($(PLATFORM), spark)
SYSTEM_PKGS += spark-drivers-pkg spark7162-drivers-pkg lirc
SYSTEM_OPKGS += spark-drivers lirc

$(TARGETPREFIX)/mymodules/lib \
$(TARGETPREFIX)/mymodules-7162/lib: | sparkkernel sparkdriver

spark-drivers-pkg: $(TARGETPREFIX)/mymodules/lib |$(HOSTPREFIX)/bin/opkg-module-deps.sh sparkfirmware
ifeq ($(SPARK7162_ONLY), )
	$(REMOVE)/spark-drivers $(PKGPREFIX)
	mkdir $(PKGPREFIX)
	cp -a $(TARGETPREFIX)/mymodules/lib $(PKGPREFIX)
	rm -fr $(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/kernel/fs/autofs4
	rm -f $(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/{build,source}
	rm -f $(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/modules.* # we call depmod after install
	cp -a $(CONTROL_DIR)/spark-drivers $(BUILD_TMP)
	opkg-module-deps.sh $(PKGPREFIX) $(BUILD_TMP)/spark-drivers/control
	DONT_STRIP=1 PKG_VER=$(KVERSION_FULL) $(OPKG_SH) $(BUILD_TMP)/spark-drivers
	$(REMOVE)/spark-drivers $(PKGPREFIX)
endif

spark7162-drivers-pkg: $(TARGETPREFIX)/mymodules-7162/lib |$(HOSTPREFIX)/bin/opkg-module-deps.sh sparkfirmware
ifeq ($(SPARK_ONLY), )
	$(REMOVE)/spark7162-drivers $(PKGPREFIX)
	mkdir $(PKGPREFIX)
	cp -a $(TARGETPREFIX)/mymodules-7162/lib $(PKGPREFIX)
	rm -fr $(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/kernel/fs/autofs4
	rm -f $(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/{build,source}
	rm -f $(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/modules.* # we call depmod after install
	cp -a $(CONTROL_DIR)/spark7162-drivers $(BUILD_TMP)
	opkg-module-deps.sh $(PKGPREFIX) $(BUILD_TMP)/spark7162-drivers/control
	DONT_STRIP=1 PKG_VER=$(KVERSION_FULL) $(OPKG_SH) $(BUILD_TMP)/spark7162-drivers
	$(REMOVE)/spark7162-drivers $(PKGPREFIX)
endif

## libpng14 does not belong here, but it saves me from building it right now
spark-directfb-pkg: \
	$(STL_ARCHIVE)/stlinux24-sh4-directfb-1.4.12+STM2011.09.27-1.sh4.rpm \
	$(STL_ARCHIVE)/stlinux24-sh4-libpng-1.4.8-3.sh4.rpm
	rm -rf $(PKGPREFIX)
	unpack-rpm.sh $(BUILD_TMP) $(STM_RELOCATE)/devkit/sh4/target $(PKGPREFIX) \
		$^
	rm -rf $(PKGPREFIX)/usr/share/man $(PKGPREFIX)/usr/share/doc
	rm $(PKGPREFIX)/usr/lib/directfb-1.4-5/inputdrivers/libdirectfb_tslib.so # no touchscreen
	rm $(PKGPREFIX)/usr/lib/directfb-1.4-5/systems/libdirectfb_x11.so        # no X11 yet
	rm $(PKGPREFIX)/usr/lib/directfb-1.4-5/systems/libdirectfb_fbdev.so      # we have stmfb
	PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
	PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_VER=1.4.12+STM2011.09.27 $(OPKG_SH) $(CONTROL_DIR)/directfb
	rm -rf $(PKGPREFIX)
endif
ifeq ($(PLATFORM), azbox)
SYSTEM_PKGS += azboxdriver

addon-drivers-pkg: azboxkernel |$(HOSTPREFIX)/bin/opkg-module-deps.sh
	$(REMOVE)/addon-drivers $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/kernel/
	set -e; cd $(PKGPREFIX)/lib/modules/$(KVERSION_FULL)/kernel/; \
		cp -a $(SOURCE_MODULE)/kernel/* ./; \
		rm -fr fs/autofs4 # is in autofs (and builtin on azbox...)
	cp -a $(CONTROL_DIR)/addon-drivers $(BUILD_TMP)
	opkg-module-deps.sh $(PKGPREFIX) $(BUILD_TMP)/addon-drivers/control
	DONT_STRIP=1 PKG_VER=$(KVERSION) $(OPKG_SH) $(BUILD_TMP)/addon-drivers
	$(REMOVE)/addon-drivers $(PKGPREFIX)
endif

AAA_BASE_DEPS =
ifeq ($(PLATFORM), spark)
AAA_BASE_DEPS += stfbcontrol fp_control ustslave libstb-hal
endif

aaa_base-pkg: $(AAA_BASE_DEPS) timezone
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)
	cp -a skel-root/common/* $(PKGPREFIX)/
	cp -a skel-root/$(PLATFORM)/* $(PKGPREFIX)/
	find $(PKGPREFIX) -name .gitignore | xargs rm
ifeq ($(PLATFORM), spark)
	test -d $(PKGPREFIX)/bin || mkdir $(PKGPREFIX)/bin
	cp -a $(TARGETPREFIX)/bin/stfbcontrol $(TARGETPREFIX)/bin/fp_control \
		$(TARGETPREFIX)/bin/ustslave \
		$(TARGETPREFIX)/bin/spark_fp \
		$(PKGPREFIX)/bin
	rm $(PKGPREFIX)/etc/init.d/start_neutrino
else
	cd $(PKGPREFIX) && rm etc/init.d/*loadmodules && rm etc/init.d/start_neutrino # ugly...
endif
	$(OPKG_SH) $(CONTROL_DIR)/aaa_base
	rm -rf $(PKGPREFIX)

pkg-index: $(HOSTPREFIX)/bin/opkg-make-index.sh
	cd $(PACKAGE_DIR) && opkg-make-index.sh . > Packages

prepare-pkginstall: pkg-index
	$(REMOVE)/install $(BUILD_TMP)/opkg.conf
	mkdir -p $(BUILD_TMP)/install/var/lib/opkg
	printf "arch all 1\narch noarch 1\narch $(BOXARCH) 10\n" > $(BUILD_TMP)/opkg.conf
	printf "src local file:/$(PACKAGE_DIR)\n" >> $(BUILD_TMP)/opkg.conf
	opkg-cl -f $(BUILD_TMP)/opkg.conf -o $(BUILD_TMP)/install update

# install-pkgs installs everything the hard way, just to check dependencies...
install-pkgs: prepare-pkginstall
	opkg-cl -f $(PATCHES)/opkg.conf -o $(BUILD_TMP)/install install $(PACKAGE_DIR)/*.opk
	# postinst does not really work on cross-arch installation... TODO: make more flexible
	test -d $(BUILD_TMP)/install/opt/pkg/lib && \
		echo "/opt/pkg/lib" > $(BUILD_TMP)/install/etc/ld.so.conf || true

# minimal-system-pkgs allows booting, not much else
minimal-system-pkgs: glibc-pkg aaa_base-pkg busybox procps opkg prepare-pkginstall
	opkg-cl -f $(BUILD_TMP)/opkg.conf -o $(BUILD_TMP)/install update
	opkg-cl -f $(BUILD_TMP)/opkg.conf -o $(BUILD_TMP)/install install \
		aaa_base busybox opkg procps
	rm -f $(BUILD_TMP)/min-root-$(PLATFORM).tar.gz
	tar -czf $(BUILD_TMP)/min-root-$(PLATFORM).tar.gz \
		--owner=0 --group=0 -C $(BUILD_TMP)/install .
	@echo
	@echo "====================================================================="
	@echo "A minimal system has been installed in $(subst $(BASE_DIR)/,,$(BUILD_TMP))/install."
	@echo "A tarball of this installation was created as"
	@echo "$(subst $(BASE_DIR)/,,$(BUILD_TMP))/min-root-$(PLATFORM).tar.gz"
	@echo "Unpack this onto an empty root fs, which will enable you to install"
	@echo "further packages via 'opkg-cl' after configuring in /etc/opkg/."
	@echo
	@echo "List of installed packages:"
	@opkg-cl -f $(BUILD_TMP)/opkg.conf -o $(BUILD_TMP)/install list-installed | \
		while read a b c; do printf "\t%-15s %s\n" $$a $$c; done
	@echo
	@echo "Have a lot of fun..."
	@echo

# system-pkgs installs actually enough to get a TV picture
system-pkgs: $(SYSTEM_PKGS)
	+make pkg-index
	opkg-cl -f $(BUILD_TMP)/opkg.conf -o $(BUILD_TMP)/install update
	opkg-cl -f $(BUILD_TMP)/opkg.conf -o $(BUILD_TMP)/install install \
		$(NEUTRINO_PKG) $(SYSTEM_OPKGS)
	@echo
	@echo "List of installed packages in $(subst $(BASE_DIR)/,,$(BUILD_TMP))/install:"
	@opkg-cl -f $(BUILD_TMP)/opkg.conf -o $(BUILD_TMP)/install list-installed | \
		while read a b c; do printf "\t%-15s %s\n" $$a $$c; done
	@echo

ifeq ($(PLATFORM), spark)
# this creates an USB stick filesystem for spark boxes
spark-system-usb:
	rm -fr $(BUILD_TMP)/install
	$(MAKE) system-pkgs
	make local-install # in flashimage.mk
	scripts/spark-usbboot.sh
	set -e; cd $(BUILD_TMP); \
		rm -fr sparksystem; mkdir sparksystem sparksystem/p1; \
		cp -a script.img uImage* sparksystem/p1; \
		cp -a install sparksystem/p2; \
		cd sparksystem; \
		tar -czf p1.tar.gz --owner=0 --group=0 -C p1 .; \
		tar -czf p2.tar.gz --owner=0 --group=0 -C p2 .
	@echo;echo;echo "There are now two directories in build_tmp/sparksystem.";\
		echo "create an USB stick with two partitions:"; \
		echo " * first partition fat16 (about 16MB)"; \
		echo " * second partition ext2 or ext3 (rest of stick)"; \
		echo "then copy the contents of build_tmp/sparksystem/p1 onto the FAT partition"; \
		echo "and the contents of build_tmp/sparksystem/p2 onto the ext2 partition."; \
		echo "Change the bootargs as explained in doc/SPARK-USB-boot.txt and have fun :-)"; \
		echo
endif

dist-pkgs: pkg-index
ifeq ($(PKG_DEST_DIR),)
	@printf "\ndist-pkgs needs the variable PKG_DEST_DIR set in config.\n\n"
	@false
else
	mkdir -pv $(PKG_DEST_DIR)
	rsync -avP --exclude=.cache --exclude=.old --exclude=.gitignore --delete \
		$(PACKAGE_DIR)/. $(PKG_DEST_DIR)/.
endif

PHONY += dist-pkgs
PHONY += glibc-pkg aaa_base-pkg pkg-index install-pkgs
PHONY += prepare-pkginstall minimal-system-pkgs system-pkgs
