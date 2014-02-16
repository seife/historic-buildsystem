# makefile to build crosstool

crosstool: $(CROSS_DIR)/bin/$(TARGET)-gcc

$(CROSS_DIR)/bin/$(TARGET)-gcc:
	$(MAKE) crosstool-new

crosstool-old: | $(SOURCE_DIR)/svn/CROSSENVIROMENT/crosstool-ng-1.3.2 $(SOURCE_DIR)/svn/CROSSENVIROMENT/crosstool-ng-configs $(ARCHIVE)/linux-2.6.26.8.tar.bz2 $(ARCHIVE)/binutils-2.19.50.0.1.tar.bz2
	make $(BUILD_TMP)
	tar --exclude='*/.svn' -cC $(SOURCE_DIR)/svn/CROSSENVIROMENT/ crosstool-ng-1.3.2 | tar -xC $(BUILD_TMP)
	set -e; unset CONFIG_SITE; cd $(BUILD_TMP)/crosstool-ng-1.3.2; \
		test "$(GIT_PROTOCOL)" = http && \
			sed -i 's#svn://svn.eglibc.org#http://www.eglibc.org/svn#' \
				scripts/build/libc/eglibc.sh || \
			true; \
		$(PATCH)/crosstool-132-bash4.diff; \
		mkdir -p patches/linux/2.6.26.8; \
		cp $(PATCHES)/linux-2.6.26.8-rename-getline.patch patches/linux/2.6.26.8; \
		cp $(PATCHES)/linux-2.6.26.8-new-make.patch       patches/linux/2.6.26.8; \
		cp $(PATCHES)/eglibc-2_8-new-make.patch           patches/eglibc/2_8/; \
		cp -a $(PATCHES)/crosstool-ng-1.3.2-newconfig .config; \
		sed -i -e 's#^CT_LOCAL_TARBALLS_DIR=.*#CT_LOCAL_TARBALLS_DIR="$(BASE_DIR)/download"#' \
		       -e 's#^CT_PREFIX_DIR=.*#CT_PREFIX_DIR="$(CROSS_BASE)"#' .config; \
		./configure --local; make; chmod 0755 ct-ng; \
		./ct-ng oldconfig; ./ct-ng build.2

UNCOOL_CT_VER = 1.19.0
crosstool-new: $(ARCHIVE)/crosstool-ng-$(UNCOOL_CT_VER).tar.bz2 $(ARCHIVE)/linux-2.6.34.13.tar.xz
	make $(BUILD_TMP)
	$(REMOVE)/crosstool-ng-$(UNCOOL_CT_VER)
	$(UNTAR)/crosstool-ng-$(UNCOOL_CT_VER).tar.bz2
	set -e; unset CONFIG_SITE LD_LIBRARY_PATH; \
		if [ x`make --version | awk '/^GNU Make/{print int($$3)}'` != x3 ]; then \
			make $(BUILD_TMP)/bin/gmake; \
			export PATH=$(BUILD_TMP)/bin:$$PATH; \
		fi; \
		cd $(BUILD_TMP)/crosstool-ng-$(UNCOOL_CT_VER); \
		cp $(PATCHES)/999-ppl-0_11_2-fix-configure-for-64bit-host.patch patches/ppl/0.11.2; \
		cp -a $(PATCHES)/crosstool-ng-coolstreamnew.config .config; \
		test "$(GIT_PROTOCOL)" = http && \
			sed -i 's/^.*CT_EGLIBC_HTTP.*/CT_EGLIBC_HTTP=y/' .config || true; \
		NUM_CPUS=$$(expr `getconf _NPROCESSORS_ONLN` \* 2); \
		MEM_512M=$$(awk '/MemTotal/ {M=int($$2/1024/512); print M==0?1:M}' /proc/meminfo); \
		test $$NUM_CPUS -gt $$MEM_512M && NUM_CPUS=$$MEM_512M; \
		test $$NUM_CPUS = 0 && NUM_CPUS=1; \
		sed -i "s@^CT_PARALLEL_JOBS=.*@CT_PARALLEL_JOBS=$$NUM_CPUS@" .config; \
		export TD_BASE_DIR=$(BASE_DIR); \
		export TD_BUILD_TMP=$(BUILD_TMP); \
		./configure --enable-local; MAKELEVEL=0 make; chmod 0755 ct-ng; \
		./ct-ng oldconfig; \
		./ct-ng build
	ln -sf sys-root/lib $(CROSS_BASE)/$(TARGET)/
	$(REMOVE)/crosstool-ng-$(UNCOOL_CT_VER)

