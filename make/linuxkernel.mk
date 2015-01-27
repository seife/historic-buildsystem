###############################################################
# stuff needed to build kernel modules(very experimental...)  #
# DO NOT TRY TO USE THIS KERNEL, IT WILL MOST LIKELY NOT WORK #
#                                                             #
# ATTENTION: the modules will probably only work with a       #
#            crosstool-built arm-cx2450x-linux-gnueabi-gcc,   #
#            or to be more precise, with the same compiler    #
#            that also built the running kernel!              #
#                                                             #
# modules are installed in $(TARGETPREFIX)/mymodules and can  #
# be picked from there.                                       #
###############################################################

ifeq ($(PLATFORM), tripledragon)
KVERSION = 2.6.12
KVERSION_FULL = $(KVERSION)
KVERSION_SRC = $(KVERSION)
K_DEP = $(D)/tdkernel
K_OBJ = $(BUILD_TMP)/linux-$(KVERSION_SRC)
endif
ifeq ($(PLATFORM), coolstream)
KVERSION = $(UNCOOL_KVER)
KVERSION_FULL = $(KVERSION)-nevis
KVERSION_SRC = $(KVERSION)
K_DEP = $(D)/cskernel
K_OBJ = $(BUILD_TMP)/kobj
endif
ifeq ($(PLATFORM), spark)
KVERSION = 2.6.32.57
KVERSION_FULL = $(KVERSION)_stm24$(PATCH_STR)
KVERSION_SRC = $(KVERSION_FULL)
K_OBJ = $(BUILD_TMP)/linux-$(KVERSION_SRC)$(K_EXTRA)
endif
ifeq ($(PLATFORM), azbox)
KVERSION = $(LINUX_AZBOX_VER)
KVERSION_FULL = $(KVERSION)-opensat
KVERSION_SRC = $(KVERSION)
K_OBJ = $(BUILD_TMP)/linux-$(KVERSION_SRC)
endif
SOURCE_MODULE = $(TARGETPREFIX)/mymodules/lib/modules/$(KVERSION_FULL)
TARGET_MODULE = $(TARGETPREFIX)/lib/modules/$(KVERSION_FULL)

ifeq ($(PLATFORM), tripledragon)
############################################################
# stuff needed to build a td kernel (very experimental...) #
############################################################
K_GCC_PATH ?= $(CROSS_BASE)/gcc-3.4.1-glibc-2.3.2/powerpc-405-linux-gnu/bin

$(BUILD_TMP)/linux-2.6.12: $(ARCHIVE)/linux-2.6.12.tar.bz2 $(PATCHES)/kernel.config-td | $(TARGETPREFIX)
	rm -rf $@ # clean up or patching will fail
	tar -C $(BUILD_TMP) -xf $(ARCHIVE)/linux-2.6.12.tar.bz2
	set -e; cd $(BUILD_TMP)/linux-2.6.12; \
		tar xvpf $(TD_SVN)/ARMAS/linux-enviroment/kernel/td_patchset_2.6.12.tar.bz2; \
		patch -p1 < kdiff_00_all.diff; \
		patch -p1 < $(PATCHES)/kernel-fix-td-build.diff; \
		mkdir -p include/stb/; \
		cp $(TARGETPREFIX)/include/hardware/os/os-generic.h include/stb -av; \
		cp $(TARGETPREFIX)/include/hardware/os/registerio.h include/stb -av; \
		cp $(TARGETPREFIX)/include/hardware/os/pversion.h include/stb -av; \
		cp $(TARGETPREFIX)/include/hardware/os/os-types.h include/stb -av; \
		cp $(PATCHES)/kernel.config-td .config

$(SOURCE_DIR)/td-dvb-wrapper:
	git clone $(GITORIOUS)/seife/td-dvb-wrapper.git $@

# td-dvb-wrapper does not strictly need tdkernel to be built (the source directory
# with some preparation would be ok), but we'd be missing the module symbols.
td-dvb-wrapper: $(SOURCE_DIR)/td-dvb-wrapper $(D)/tdkernel
	PATH=$(K_GCC_PATH):$(PATH) make find-powerpc-405-linux-gnu-gcc
	set -e; cd $(BUILD_TMP)/linux-2.6.12; \
		export PATH=$(BASE_DIR)/ccache:$(K_GCC_PATH):$(PATH); \
		make ARCH=ppc CROSS_COMPILE=powerpc-405-linux-gnu- M=$(SOURCE_DIR)/td-dvb-wrapper ;\
		make ARCH=ppc CROSS_COMPILE=powerpc-405-linux-gnu- M=$(SOURCE_DIR)/td-dvb-wrapper \
			INSTALL_MOD_PATH=$(TARGETPREFIX)/mymodules modules_install
	# hack: put the frontend.h into a place where it will be found but which
	# does not conflict with system headers.
	install -d $(TARGETPREFIX)/include/hardware/linux/dvb
	cp -a $(SOURCE_DIR)/td-dvb-wrapper/frontend.h $(TARGETPREFIX)/include/hardware/linux/dvb/

$(TARGET_MODULE)/extra/td-dvb-frontend.ko: td-dvb-wrapper
	install -m 644 -D $(SOURCE_MODULE)/extra/td-dvb-frontend.ko $@

ifneq ($(TD_COMPILER), old)
TDK_DEPS = $(K_GCC_PATH)/powerpc-405-linux-gnu-gcc
endif
$(D)/tdkernel: $(TDK_DEPS) $(BUILD_TMP)/linux-2.6.12
	set -e; cd $(BUILD_TMP)/linux-2.6.12; \
		export PATH=$(BASE_DIR)/ccache:$(K_GCC_PATH):$(PATH); \
		make	ARCH=ppc CROSS_COMPILE=powerpc-405-linux-gnu- oldconfig; \
		$(MAKE)	ARCH=ppc CROSS_COMPILE=powerpc-405-linux-gnu- all; \
		make	ARCH=ppc CROSS_COMPILE=powerpc-405-linux-gnu- \
			INSTALL_MOD_PATH=$(TARGETPREFIX)/mymodules modules_install
	$(MAKE) fuse-driver
	touch $@

# 2.7.5 is the last version which has a kernel module packaged...
fuse-driver: $(ARCHIVE)/fuse-2.7.5.tar.gz
	$(UNTAR)/fuse-2.7.5.tar.gz
	set -e; cd $(BUILD_TMP)/fuse-2.7.5/; \
		$(PATCH)/fuse-kernel-add-devfs.diff ; \
		cd kernel; \
		export PATH=$(BASE_DIR)/ccache:$(K_GCC_PATH):$(PATH); \
		./configure --with-kernel=$(BUILD_TMP)/linux-2.6.12 --enable-kernel-module; \
		$(MAKE) ARCH=ppc CROSS_COMPILE=powerpc-405-linux-gnu- \
			DESTDIR=$(TARGETPREFIX)/mymodules install
	$(REMOVE)/fuse-2.7.5

ramzswap-driver: $(ARCHIVE)/compcache-0.6.2.tar.gz $(PATCHES)/compcache-0.6.2-backport-to-2.6.12.diff
	$(REMOVE)/compcache-0.6.2
	$(UNTAR)/compcache-0.6.2.tar.gz
	set -e; cd $(BUILD_TMP)/compcache-0.6.2; \
		$(PATCH)/compcache-0.6.2-backport-to-2.6.12.diff; \
		export PATH=$(BASE_DIR)/ccache:$(K_GCC_PATH):$(PATH); \
		$(MAKE) ARCH=ppc CROSS_COMPILE=powerpc-405-linux-gnu- \
			KERNEL_BUILD_PATH=$(BUILD_TMP)/linux-$(KVERSION); \
		make -j1 ARCH=ppc CROSS_COMPILE=powerpc-405-linux-gnu- \
			KERNEL_BUILD_PATH=$(BUILD_TMP)/linux-$(KVERSION) \
			INSTALL_MOD_DIR=kernel/drivers/extra \
			INSTALL_MOD_PATH=$(TARGETPREFIX)/mymodules modules_install
	$(REMOVE)/compcache-0.6.2

kernelmenuconfig: $(BUILD_TMP)/linux-2.6.12 $(TDK_DEPS)
	set -e; cd $(BUILD_TMP)/linux-2.6.12; \
		export PATH=$(BASE_DIR)/ccache:$(K_GCC_PATH):$(PATH); \
		make	ARCH=ppc CROSS_COMPILE=powerpc-405-linux-gnu- menuconfig

# try to build a compiler that's similar to the one that built the kernel...
# this should be only needed if you are using e.g. an external toolchain with gcc4
kernelgcc: $(K_GCC_PATH)/powerpc-405-linux-gnu-gcc

# powerpc-405-linux-gnu-gcc is the "marker file" for crosstool
$(K_GCC_PATH)/powerpc-405-linux-gnu-gcc: | $(ARCHIVE)/crosstool-0.43.tar.gz
	tar -C $(BUILD_TMP) -xzf $(ARCHIVE)/crosstool-0.43.tar.gz
	cp $(PATCHES)/glibc-2.3.3-allow-gcc-4.0-configure.patch $(BUILD_TMP)/crosstool-0.43/patches/glibc-2.3.2
	cp $(PATCHES)/glibc-2.3.6-new_make.patch                $(BUILD_TMP)/crosstool-0.43/patches/glibc-2.3.2
	set -e; unset CONFIG_SITE LD_LIBRARY_PATH; \
		if [ x`make --version | awk '/^GNU Make/{print int($$3)}'` != x3 ]; then \
			make $(BUILD_TMP)/bin/gmake; \
			export PATH=$(BUILD_TMP)/bin:$$PATH; \
		fi; \
		cd $(BUILD_TMP)/crosstool-0.43; \
		NUM_CPUS=$$(expr `getconf _NPROCESSORS_ONLN` \* 2); \
		MEM_512M=$$(awk '/MemTotal/ {M=int($$2/1024/512); print M==0?1:M}' /proc/meminfo); \
		test $$NUM_CPUS -gt $$MEM_512M && NUM_CPUS=$$MEM_512M; \
		test $$NUM_CPUS = 0 && NUM_CPUS=1; \
		$(PATCH)/crosstool-0.43-fix-build-with-FORTIFY_SOURCE-default.diff; \
		$(PATCH)/crosstool-0.43-fix-glibc-build-with-non-bash-as-system-shell.diff; \
		export TARBALLS_DIR=$(ARCHIVE); \
		export RESULT_TOP=$(CROSS_BASE); \
		export GCC_LANGUAGES="c"; \
		export PARALLELMFLAGS="-j $$NUM_CPUS"; \
		export QUIET_EXTRACTIONS=y; \
		eval `cat powerpc-405.dat gcc-3.4.1-glibc-2.3.2.dat` LINUX_DIR=linux-2.6.12 sh all.sh --notest
	$(REMOVE)/crosstool-0.43
endif

ifeq ($(PLATFORM), coolstream)
ifeq ($(KVERSION), 2.6.26.8)
K_EXT = bz2
K_ADDR = 0x17048000
else
K_EXT = xz
K_ADDR = 0x048000
endif
KPATCHDEPS = $(wildcard $(PATCHES)/cskernel/$(KVERSION)/*)
KPATCHDEPS += $(wildcard $(PATCHES)/cskernel-extra/$(KVERSION)/*)
$(BUILD_TMP)/linux-$(KVERSION_SRC): $(ARCHIVE)/linux-$(KVERSION).tar.$(K_EXT) $(KPATCHDEPS)
	rm -rf $@
	tar -C $(BUILD_TMP) -xf $(ARCHIVE)/linux-$(KVERSION).tar.$(K_EXT)
	set -e; cd $@ ; \
		for i in $(PATCHES)/cskernel/$(KVERSION)/* $(PATCHES)/cskernel-extra/$(KVERSION)/*; do \
			test -e $$i || continue; \
			echo "applying $${i#$(PATCHES)/}..." ;patch -p1 -i $$i; \
		done ; \

# this would be a way to build custom configs, but it is not nice, so not used yet.
# CS_K_Y = CONFIG_HID_SUPPORT
# CS_K_M = CONFIG_HID
# CS_K_N = CONFIG_HID_DEBUG
# CS_K_N += CONFIG_HIDRAW
# CS_K_M += CONFIG_USB_HID
# CS_K_N += CONFIG_USB_HIDINPUT_POWERBOOK
# CS_K_N += CONFIG_HID_FF
# CS_K_N += CONFIG_USB_HIDDEV
# CS_K_N += CONFIG_USB_KBD
# CS_K_N += CONFIG_USB_MOUSE
# CS_K_Y += CONFIG_USB_EZUSB
# CS_K_Y += CONFIG_USB_SERIAL_GENERIC
# CS_K_M += CONFIG_USB_SERIAL_BELKIN
# CS_K_M += CONFIG_USB_SERIAL_CP2101
# CS_K_M += CONFIG_USB_SERIAL_KEYSPAN_PDA
# CS_K_M += CONFIG_USB_SERIAL_MCT_U232
# CS_K_M += CONFIG_AUTOFS4_FS
# CS_K_M += CONFIG_ISO9660_FS
# CS_K_Y += CONFIG_JOLIET
# CS_K_N += CONFIG_ZISOFS
# CS_K_M += CONFIG_UDF_FS
# CS_K_Y += CONFIG_UDF_NLS
# CS_K_M += CONFIG_NFSD
# CS_K_Y += CONFIG_NFSD_V3
# CS_K_N += CONFIG_NFSD_V3_ACL
# CS_K_N += CONFIG_NFSD_V4
# CS_K_M += CONFIG_EXPORTFS
# 		for i in $(CS_K_Y); do sed -i "/^\(# \)*$$i[= ]/d" .config; done && \
# 		for i in $(CS_K_Y); do echo "$$i=y" >> .config; done && \
# 		for i in $(CS_K_M); do sed -i "/^\(# \)*$$i[= ]/d" .config; done && \
# 		for i in $(CS_K_M); do echo "$$i=m" >> .config; done && \
# 		for i in $(CS_K_N); do sed -i "/^\(# \)*$$i[= ]/d" .config; done && \
# 		for i in $(CS_K_N); do echo "# $$i is not set" >> .config; done && \

$(HOSTPREFIX)/bin/mkimage: cs-uboot

K_SRCDIR ?= $(SOURCE_DIR)/linux

$(K_SRCDIR):
	@echo
	@echo "you need to create "$(subst $(BASE_DIR)/,"",$(K_SRCDIR))" first."
	@echo "there are several ways to do this:"
	@echo "* 'make kernel-git'   downloads the kernel from the Coolstream SVN"
	@echo "                      and creates a symlink"
	@echo "* 'make kernel-patch' extracts a tarball and patches it with the"
	@echo "                      patches from archive-patches"
	@echo "note that kernel-git is usually safer and more current, but takes"
	@echo "longer and uses more download bandwidth."
	@echo
	@false

kernel-git: $(UNCOOL_GIT)/cst-public-linux-kernel
	cd $(UNCOOL_GIT)/cst-public-linux-kernel && \
		git branch -r | while read b; do \
			if git branch | grep -q " $${b##*/}$$"; then \
				git branch --set-upstream $${b##*/} $$b; \
			else \
				git branch --track $${b##*/} $$b; \
			fi; \
		done
	cd $(SOURCE_DIR) && git clone $(UNCOOL_GIT)/cst-public-linux-kernel linux-$(KVERSION)-cnxt
	cd $(SOURCE_DIR)/linux-$(KVERSION)-cnxt && git checkout $(KVERSION)-cnxt
	rm -f $(SOURCE_DIR)/linux
	ln -s linux-$(KVERSION)-cnxt $(SOURCE_DIR)/linux

kernel-patch: $(BUILD_TMP)/linux-$(KVERSION)
	rm -f $(SOURCE_DIR)/linux
	ln -s $(BUILD_TMP)/linux-$(KVERSION) $(SOURCE_DIR)/linux

$(K_OBJ)/.config: $(PATCHES)/cskernel-$(KVERSION).config
	mkdir -p $(K_OBJ)
	cp $< $@

$(D)/cskernel: $(K_SRCDIR) $(K_OBJ)/.config | $(HOSTPREFIX)/bin/mkimage
ifeq ($(K_SRCDIR), $(SOURCE_DIR)/linux)
	# we need this to build out of tree - kbuild complains otherwise
	# whoever sets K_SRCDIR to something else should better know what he's doing anyway
	rm -f $(SOURCE_DIR)/linux/.config
endif
	set -e; cd $(SOURCE_DIR)/linux; \
		make ARCH=arm CROSS_COMPILE=$(TARGET)- silentoldconfig O=$(K_OBJ)/; \
		$(MAKE) ARCH=arm CROSS_COMPILE=$(TARGET)- O=$(K_OBJ)/; \
		make ARCH=arm CROSS_COMPILE=$(TARGET)- INSTALL_MOD_PATH=$(TARGETPREFIX)/mymodules \
			modules_install O=$(K_OBJ)/
	cd $(BUILD_TMP) && \
		mkimage -A arm -O linux -T kernel -a $(K_ADDR) -e $(K_ADDR) -C none \
			-n "CS HDx Kernel $(UNCOOL_KVER) (zImage)" -d $(K_OBJ)/arch/arm/boot/zImage zImage.img
	cd $(BUILD_TMP) && \
		mkimage -A arm -O linux -T kernel -a $(K_ADDR) -e $(K_ADDR) -C none \
			-n "CS HDx Kernel $(UNCOOL_KVER)" -d $(K_OBJ)/arch/arm/boot/Image Image.img
	: touch $@

kernelmenuconfig: $(K_SRCDIR) $(K_OBJ)/.config
ifeq ($(K_SRCDIR), $(SOURCE_DIR)/linux)
	rm -f $(SOURCE_DIR)/linux/.config
endif
	cd $(SOURCE_DIR)/linux && \
		make ARCH=arm CROSS_COMPILE=$(TARGET)- menuconfig O=$(K_OBJ)/

# yes, it's not the kernel. but it's not enough to warrant an extra file
$(D)/cs-uboot: $(ARCHIVE)/u-boot-2009.03.tar.bz2 $(PATCHES)/coolstream/u-boot-2009.3-CST.diff
	$(REMOVE)/u-boot-2009.03
	$(UNTAR)/u-boot-2009.03.tar.bz2
	set -e; cd $(BUILD_TMP)/u-boot-2009.03; \
		$(PATCH)/coolstream/u-boot-2009.3-CST.diff; \
		make coolstream_hdx_config; \
		$(MAKE)
	cp -a $(BUILD_TMP)/u-boot-2009.03/tools/mkimage $(HOSTPREFIX)/bin
	touch $@
endif

ifeq ($(PLATFORM), spark)
TMP_KDIR=$(BUILD_TMP)/linux-2.6.32
TDT_PATCHES=$(TDT_SRC)/tdt/cvs/cdk/Patches

MY_KERNELPATCHES = $(PATCHES)/0001-bpa2-ignore-bigphysarea-kernel-parameter.patch
ifeq ($(PATCH_STR),"_0209")
MY_KERNELPATCHES += $(PATCHES)/0001-spark-fix-buffer-overflow-in-lirc_stm.patch
endif

# this is ugly, but easier than changing the way the tdt patches are applied.
# The reason for this patch is, that the spark_setup and spark7162_setup patches
# can not both be applied, because they overlap in a single file. The spark7162
# patch has everything that's needed in this file, so I partly revert the former...
$(TDT_PATCHES)/linux-sh4-seife-revert-spark_setup_stmmac_mdio.patch: \
		$(PATCHES)/linux-sh4-seife-revert-spark_setup_stmmac_mdio.patch
	ln -sf $(PATCHES)/linux-sh4-seife-revert-spark_setup_stmmac_mdio.patch $(TDT_PATCHES)

# if you only want to build for one version, set SPARK_ONLY=1 or SPARK7162_ONLY=1 in config
SPARKKERNELDEPS =
ifeq ($(SPARK7162_ONLY), )
SPARKKERNELDEPS += $(PATCHES)/kernel.config-spark
endif
ifeq ($(SPARK_ONLY), )
SPARKKERNELDEPS += $(PATCHES)/kernel.config-spark7162
endif

$(BUILD_TMP)/linux-$(KVERSION_SRC): \
		$(STL_ARCHIVE)/stlinux24-host-kernel-source-sh4-$(KVERSION_FULL)-$(subst _0,,$(PATCH_STR)).src.rpm \
		$(MY_KERNELPATCHES) \
		$(SPARK_PATCHES_24:%=$(TDT_PATCHES)/%) \
		$(SPARKKERNELDEPS)
	unpack-rpm.sh $(BUILD_TMP) "" $(BUILD_TMP)/ksrc $<
	rm -fr $(TMP_KDIR)
	tar -C $(BUILD_TMP) -xf $(BUILD_TMP)/ksrc/linux-2.6.32.tar.bz2
	set -e; cd $(TMP_KDIR); \
		bzcat $(BUILD_TMP)/ksrc/linux-$(KVERSION).patch.bz2 | patch -p1 ;\
		bzcat $(BUILD_TMP)/ksrc/linux-$(KVERSION)_stm24_sh4$(PATCH_STR).patch.bz2 | patch -p1; \
		for i in $(SPARK_PATCHES_24); do \
			echo "==> Applying Patch: $$i"; \
			patch -p1 -i $(TDT_PATCHES)/$$i; \
		done; \
		for i in $(MY_KERNELPATCHES); do \
			echo "==> Applying Patch: $(subst $(PATCHES)/,'',$$i)"; \
			patch -p1 -i $$i; \
		done; \
		cp $(PATCHES)/kernel.config-spark     .config-spark; \
		cp $(PATCHES)/kernel.config-spark7162 .config-7162; \
		sed -i "s#^\(CONFIG_EXTRA_FIRMWARE_DIR=\).*#\1\"$(TDT_SRC)/tdt/cvs/cdk/integrated_firmware\"#" .config-*;
	rm -fr $@ $@-7162
	mv $(BUILD_TMP)/linux-2.6.32 $@
	cp -al $@ $@-7162 # hardlinked tree
	mv $@/.config-spark $@/.config
	mv $@-7162/.config-7162 $@-7162/.config
	# this allows to compile old 0209 kernel with 0210 config without questions...
	echo "CONFIG_HW_GLITCH_WIDTH=1" >> $@/.config
	echo "CONFIG_HW_GLITCH_WIDTH=1" >> $@-7162/.config
	$(MAKE) -C $@ ARCH=sh oldconfig
	$(MAKE) -C $@ ARCH=sh include/asm
	$(MAKE) -C $@ ARCH=sh include/linux/version.h
	$(MAKE) -C $@ ARCH=sh CROSS_COMPILE=$(TARGET)- modules_prepare
	$(MAKE) -C $@-7162 ARCH=sh oldconfig
	$(MAKE) -C $@-7162 ARCH=sh include/asm
	$(MAKE) -C $@-7162 ARCH=sh include/linux/version.h
	$(MAKE) -C $@-7162 ARCH=sh CROSS_COMPILE=$(TARGET)- modules_prepare

kernelmenuconfig: $(BUILD_TMP)/linux-$(KVERSION_SRC)$(K_EXTRA)
	make -C$^ ARCH=sh CROSS_COMPILE=$(TARGET)- menuconfig

_sparkkernel: $(BUILD_TMP)/linux-$(KVERSION_SRC)$(K_EXTRA)
	set -e; cd $(BUILD_TMP)/linux-$(KVERSION_SRC)$(K_EXTRA); \
		export PATH=$(CROSS_BASE)/host/bin:$(PATH); \
		$(MAKE) ARCH=sh CROSS_COMPILE=$(TARGET)- uImage modules; \
		make    ARCH=sh CROSS_COMPILE=$(TARGET)- \
			INSTALL_MOD_PATH=$(TARGETPREFIX)/mymodules$(K_EXTRA) modules_install; \
		cp -L arch/sh/boot/uImage $(BUILD_TMP)/uImage$(K_EXTRA)

sparkkernel: $(BUILD_TMP)/linux-$(KVERSION_SRC)
ifeq ($(SPARK7162_ONLY), )
	$(MAKE) _sparkkernel
endif
ifeq ($(SPARK_ONLY), )
	$(MAKE) _sparkkernel K_EXTRA=-7162
endif

$(TARGETPREFIX)/include/linux/dvb:
	mkdir -p $@

# the dependency on .../tdt-driver/.git should trigger on updated git...
$(BUILD_TMP)/tdt-driver: \
$(SOURCE_DIR)/tdt-driver/.git \
$(PATCHES)/sparkdrivers/0001-player2_191-silence-kmsg-spam.patch \
$(PATCHES)/sparkdrivers/0002-e2proc-silence-kmsg-spam.patch \
$(PATCHES)/sparkdrivers/0003-pti-silence-kmsg-spam.patch \
$(PATCHES)/sparkdrivers/0004-stmfb-silence-kmsg-spam.patch \
$(PATCHES)/sparkdrivers/0005-frontends-spark_dvbapi5-silence-kmsg-spam.patch \
$(PATCHES)/sparkdrivers/0006-frontends-spark7162-silence-kmsg-spam.patch \
$(PATCHES)/sparkdrivers/0001-import-cec-from-pinky-s-git.patch \
$(PATCHES)/sparkdrivers/0002-aotom-fix-include-file.patch \
$(PATCHES)/sparkdrivers/0003-aotom-add-VFDGETVERSION-ioctl-to-find-FP-type.patch \
$(PATCHES)/sparkdrivers/0004-aotom-improve-scrolling-text-code.patch \
$(PATCHES)/sparkdrivers/0005-aotom-speed-up-softi2c-lowering-CPU-load-of-aotom-dr.patch \
$(PATCHES)/sparkdrivers/0006-aotom-add-additional-chars-for-VFD-fix-missing-chars.patch \
$(PATCHES)/sparkdrivers/0007-aotom-register-reboot_notifier-implement-rtc-driver.patch \
| $(TARGETPREFIX)/include/linux/dvb
	rm -fr $@ $@-7162
	cp -a $(SOURCE_DIR)/tdt-driver $(BUILD_TMP)
	set -e; cd $@; \
		for i in $^; do \
			test -d $$i && continue; \
			echo "==> Applying Patch: $${i#$(PATCHES)/}"; \
			patch -p1 -i $$i; done; \
		cp -a bpamem/bpamem.h $(TARGETPREFIX)/include; \
		rm -f player2 multicom; \
		ln -s player2_191 player2; \
		ln -s multicom-3.2.4 multicom; \
		rm -f .config; printf "export CONFIG_PLAYER_191=y\nexport CONFIG_MULTICOM324=y\n" > .config; \
		cp player2/linux/include/linux/dvb/stm_ioctls.h $(TARGETPREFIX)/include/linux/dvb; \
		cd include; \
		rm -f stmfb player2 multicom; \
		ln -s stmfb-3.1_stm24_0102 stmfb; \
		ln -s player2_179 player2; \
		ln -s ../multicom-3.2.4/include multicom; \
		cd ../stgfb; \
		rm -f stmfb; \
		ln -s stmfb-3.1_stm24_0102 stmfb; \
		cp -a stmfb/linux/drivers/video/stmfb.h $(TARGETPREFIX)/include/linux
	cp -a $@/frontcontroller/aotom/aotom_main.h $(TARGETPREFIX)/include
	# disable wireless build
	sed -i 's/^\(obj-y.*+= wireless\)/# \1/' $@/Makefile
	# disable led and button - it's not for spark
	sed -i 's@^\(obj-y.*+= \(led\|button\)/\)@# \1@' $@/Makefile
	cp -al $@ $@-7162

# CONFIG_MODULES_PATH= is needed because the Makefile contains
# "-I$(CONFIG_MODULES_PATH)/usr/include". With CONFIG_MODULES_PATH unset,
# host system includes are used and that might be fatal.
_sparkdriver: $(BUILD_TMP)/tdt-driver$(K_EXTRA) | $(BUILD_TMP)/linux-$(KVERSION_SRC)$(K_EXTRA)
	$(MAKE) -C $(BUILD_TMP)/linux-$(KVERSION_SRC)$(K_EXTRA) ARCH=sh \
		CONFIG_MODULES_PATH=$(CROSS_DIR)/target \
		KERNEL_LOCATION=$(BUILD_TMP)/linux-$(KVERSION_SRC)$(K_EXTRA) \
		DRIVER_TOPDIR=$(BUILD_TMP)/tdt-driver$(K_EXTRA) \
		M=$(firstword $^) \
		PLAYER191=player191 \
		CROSS_COMPILE=$(TARGET)-
	make    -C $(BUILD_TMP)/linux-$(KVERSION_SRC)$(K_EXTRA) ARCH=sh \
		CONFIG_MODULES_PATH=$(CROSS_DIR)/target \
		KERNEL_LOCATION=$(BUILD_TMP)/linux-$(KVERSION_SRC)$(K_EXTRA) \
		DRIVER_TOPDIR=$(BUILD_TMP)/tdt-driver$(K_EXTRA) \
		M=$(firstword $^) \
		PLAYER191=player191 \
		CROSS_COMPILE=$(TARGET)- \
		INSTALL_MOD_PATH=$(TARGETPREFIX)/mymodules$(K_EXTRA) modules_install

sparkdriver:
ifeq ($(SPARK7162_ONLY), )
	$(MAKE) _sparkdriver SPARK=1
endif
ifeq ($(SPARK_ONLY), )
	$(MAKE) _sparkdriver SPARK7162=1 K_EXTRA=-7162
	find $(TARGETPREFIX)/mymodules-7162 -name stmcore-display-sti7106.ko | \
		xargs -r rm # we don't have a 7106 chip
endif

sparkfirmware: $(STL_ARCHIVE)/stlinux24-sh4-stmfb-firmware-1.20-1.noarch.rpm
	unpack-rpm.sh $(BUILD_TMP) $(STM_RELOCATE)/devkit/sh4/target $(TARGETPREFIX)/mymodules $^
	unpack-rpm.sh $(BUILD_TMP) $(STM_RELOCATE)/devkit/sh4/target $(TARGETPREFIX)/mymodules-7162 $^
	ln -sf component_7111_mb618.fw	 $(TARGETPREFIX)/mymodules/lib/firmware/component.fw
	ln -sf component_7105_hdk7105.fw $(TARGETPREFIX)/mymodules-7162/lib/firmware/component.fw
	ln -sf fdvo0_7105.fw		 $(TARGETPREFIX)/mymodules-7162/lib/firmware/fdvo0.fw


endif

ifeq ($(PLATFORM), azbox)

$(SOURCE_DIR)/genzbf:
	mkdir $@
	set -e; cd $@; \
		wget -O genzbf.c 'http://azboxopenpli.git.sourceforge.net/git/gitweb.cgi?p=azboxopenpli/openembedded;a=blob_plain;f=recipes/linux/linux-azbox/genzbf.c;hb=HEAD'; \
		wget -O zboot.h  'http://azboxopenpli.git.sourceforge.net/git/gitweb.cgi?p=azboxopenpli/openembedded;a=blob_plain;f=recipes/linux/linux-azbox/zboot.h;hb=HEAD'

INITRAMFS_ME     = $(ARCHIVE)/initramfs-azboxme-oe-core-$(KVERSION)-$(AZBOX_INITRAMFS_ME).tar.bz2
INITRAMFS_MINIME = $(ARCHIVE)/initramfs-azboxminime-oe-core-$(KVERSION)-$(AZBOX_INITRAMFS_MINIME).tar.bz2 \

$(BUILD_TMP)/linux-$(KVERSION_SRC)/initramfs: \
$(INITRAMFS_ME) $(INITRAMFS_MINIME) \
$(PATCHES)/initramfs-azboxmeminime-init
	rm -rf $(BUILD_TMP)/minime $(BUILD_TMP)/me
	mkdir $(BUILD_TMP)/minime $(BUILD_TMP)/me
	tar -C $(BUILD_TMP)/me     -xf $(INITRAMFS_ME)
	tar -C $(BUILD_TMP)/minime -xf $(INITRAMFS_MINIME)
	rm -rf $@
	cp -a $(BUILD_TMP)/me/linux-$(KVERSION)/initramfs $@
	set -e; cd $(BUILD_TMP)/minime/linux-$(KVERSION)/initramfs/lib/modules/$(KVERSION_FULL)/kernel/drivers; \
		cp -a nand_wr.ko $@/lib/modules/$(KVERSION_FULL)/kernel/drivers/nand_wrminime.ko; \
		cp -a irvfdminime.ko $@/lib/modules/$(KVERSION_FULL)/kernel/drivers/; \
		cp -a xload-38x/audio_*_dts52.xload $@/lib/modules/$(KVERSION_FULL)/kernel/drivers/xload-38x
	set -e; cd $(BUILD_TMP)/minime/linux-$(KVERSION)/initramfs/usr/bin; \
		cp -a progmicom_minime* $@/usr/bin; \
		cp -a webinterface $@/usr/bin/webinterfaceminime;
	set -e; cd $@/lib/modules/$(KVERSION_FULL)/kernel/drivers; \
		mv nand_wr.ko nand_wrme.ko; \
		ln -s nand_wrme.ko nand_wr.ko
	cp -a $(lastword $^) $@/init
	chmod 755 $@/init
	sed -i 's/^root:.*/root::10933:0:99999:7:::/' $@/etc/shadow # empty rootpassword for rescue

# these are from https://github.com/OpenAZBox/oe-core/tree/master/meta-openpli/recipes-linux/linux/
AZBOX_KPATCHES =  kernel-3.9.2.patch
AZBOX_KPATCHES += add-dmx-source-timecode.patch
AZBOX_KPATCHES += af9015-output-full-range-SNR.patch af9033-output-full-range-SNR.patch
AZBOX_KPATCHES += as102-adjust-signal-strength-report.patch as102-scale-MER-to-full-range.patch
AZBOX_KPATCHES += cinergy_s2_usb_r2.patch cxd2820r-output-full-range-SNR.patch
AZBOX_KPATCHES += dvb-usb-dib0700-disable-sleep.patch dvb_usb_disable_rc_polling.patch
AZBOX_KPATCHES += it913x-switch-off-PID-filter-by-default.patch tda18271-advertise-supported-delsys.patch
AZBOX_KPATCHES += fix-dvb-siano-sms-order.patch mxl5007t-add-no_probe-and-no_reset-parameters.patch
AZBOX_KPATCHES += 0001-rt2800usb-add-support-for-rt55xx.patch
AZBOX_KPATCHES += 0001-Revert-MIPS-Fix-potencial-corruption.patch

$(BUILD_TMP)/linux-$(KVERSION_SRC): \
$(PATCHES)/kernel.config-azbox-$(KVERSION) \
$(ARCHIVE)/linux-$(KVERSION_SRC).tar.xz \
$(AZBOX_KPATCHES:%=$(PATCHES)/azboxkernel/$(KVERSION)/%)
	rm -fr $@
	$(UNTAR)/linux-$(KVERSION_SRC).tar.xz
	set -e; cd $@; \
		for i in $(AZBOX_KPATCHES); do \
			echo "===> applying $$i"; \
			$(PATCH)/azboxkernel/$(KVERSION)/$$i; \
		done; \
		sed -i 's/ -static//' scripts/Makefile.host; \
		cp $(PATCHES)/kernel.config-azbox-$(KVERSION) .config; \
		make ARCH=mips CROSS_COMPILE=$(TARGET)- oldconfig

$(BUILD_TMP)/linux-$(KVERSION_SRC)/arch/mips/boot/genzbf: $(SOURCE_DIR)/genzbf
	set -e; cd $(SOURCE_DIR)/genzbf; \
		gcc -W -Wall -O2 -o $@ genzbf.c

# genromfs is e.g in a package called.... "genromfs"! (openSUSE)
azboxkernel: $(BUILD_TMP)/linux-$(KVERSION_SRC) $(BUILD_TMP)/linux-$(KVERSION_SRC)/initramfs $(BUILD_TMP)/linux-$(KVERSION_SRC)/arch/mips/boot/genzbf find-genromfs
	set -e;cd $(BUILD_TMP)/linux-$(KVERSION_SRC); \
		$(MAKE) ARCH=mips CROSS_COMPILE=$(TARGET)- zbimage-linux-xload; \
		$(MAKE) ARCH=mips CROSS_COMPILE=$(TARGET)- modules; \
		$(MAKE) ARCH=mips CROSS_COMPILE=$(TARGET)- \
			INSTALL_MOD_PATH=$(TARGETPREFIX)/mymodules modules_install
	set -e; cd $(BUILD_TMP); \
		rm -f azboxkernel.tar; \
		tar -cvpf azboxkernel.tar -C linux-$(KVERSION_SRC) zbimage-linux-xload

AZ_DRIVER_TMPL = dvb-modules-$(LINUX_AZBOX_VER)-opensat-oe-core-$(AZBOX_DVB_M_VER).tar.gz

azboxdriver: $(ARCHIVE)/azboxme-$(AZ_DRIVER_TMPL) $(ARCHIVE)/azboxminime-$(AZ_DRIVER_TMPL)
	$(REMOVE)/azboxme-dvb-modules $(PKGPREFIX) $(BUILD_TMP)/azboxme-dvb-drivers
	set -e; cd $(BUILD_TMP); \
		mkdir azboxme-dvb-modules; \
		cd azboxme-dvb-modules; \
		for i in me minime; do \
			mkdir $$i; \
			tar -C $$i -xf $(ARCHIVE)/azbox$${i}-$(AZ_DRIVER_TMPL); \
			cp $$i/* .; \
			mv sci.ko sci$${i}.ko; \
		done; \
		if ! diff --exclude='sci*.ko' me/ minime/; then \
			echo "too many differences in driver tarball"; false; fi; \
		rm -r me minime; \
		install -d lib/modules/$(KVERSION_FULL)/extra; \
		install -d lib/firmware; \
		mv *.fw lib/firmware; \
		mv *.ko lib/modules/$(KVERSION_FULL)/extra; \
		rm -f staticdevices.tar.gz.install
	install -d $(PKGPREFIX)/etc/init.d
	cp -a skel-root/$(PLATFORM)/etc/init.d/*loadmodules $(PKGPREFIX)/etc/init.d
	mv $(BUILD_TMP)/azboxme-dvb-modules/* $(PKGPREFIX)
	cp -a $(CONTROL_DIR)/azboxme-dvb-drivers $(BUILD_TMP)
	opkg-module-deps.sh $(PKGPREFIX) $(BUILD_TMP)/azboxme-dvb-drivers/control
	# who comes up with such crap versioning... :-(
	bash -c 'T=$(AZBOX_DVB_M_VER); AZ_VER="$${T:4}$${T:2:2}$${T::2}"; \
		DONT_STRIP=1 PKG_VER=$(KVERSION).$$AZ_VER $(OPKG_SH) $(BUILD_TMP)/azboxme-dvb-drivers'
	$(REMOVE)/azboxme-dvb-drivers $(PKGPREFIX)
endif


# rule for the autofs4 module - needed by the automounter
# installs the already built module into the "proper" path
$(TARGET_MODULE)/kernel/fs/autofs4/autofs4.ko: $(K_DEP)
	install -m 644 -D $(SOURCE_MODULE)/kernel/fs/autofs4/autofs4.ko $@
	make depmod

# input drivers: usbhid, evdev
inputmodules: $(D)/cskernel
	mkdir -p $(TARGET_MODULE)/kernel/drivers
	cp -a	$(SOURCE_MODULE)/kernel/drivers/input $(SOURCE_MODULE)/kernel/drivers/hid \
		$(TARGET_MODULE)/kernel/drivers/
	make depmod

# helper target...
depmod:
	PATH=$(PATH):/sbin:/usr/sbin depmod -b $(TARGETPREFIX) $(KVERSION_FULL)
	mv $(TARGET_MODULE)/modules.dep $(TARGET_MODULE)/.modules.dep
	rm $(TARGET_MODULE)/modules.*
	mv $(TARGET_MODULE)/.modules.dep $(TARGET_MODULE)/modules.dep
