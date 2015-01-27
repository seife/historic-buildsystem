# makefile to build crosstool

crosstool: $(CROSS_DIR)/bin/$(TARGET)-gcc

ifeq ($(TD_COMPILER), old)
$(CROSS_DIR)/bin/$(TARGET)-gcc: $(ARCHIVE)/crosstool-0.43.tar.gz | $(BUILD_TMP)
	@echo ' ============================================================================== '
	@echo "                       Preparing to Build crosstool"
	@echo ' ============================================================================== '
	@echo ' '
	tar -C $(BUILD_TMP) -xzf $(ARCHIVE)/crosstool-0.43.tar.gz
	cp $(PATCHES)/glibc-2.3.6-allow-binutils-2.20+.patch $(BUILD_TMP)/crosstool-0.43/patches/glibc-2.3.6
	cp $(PATCHES)/glibc-2.3.6-new_make.patch             $(BUILD_TMP)/crosstool-0.43/patches/glibc-2.3.6
	set -e; unset CONFIG_SITE; cd $(BUILD_TMP)/crosstool-0.43; \
		$(PATCH)/crosstool-0.43-fix-build-with-FORTIFY_SOURCE-default.diff; \
		$(PATCH)/crosstool-0.43-fix-glibc-build-with-non-bash-as-system-shell.diff; \
		export TARBALLS_DIR=$(ARCHIVE); \
		export RESULT_TOP=$(CROSS_BASE); \
		export GCC_LANGUAGES="c,c++"; \
		export PARALLELMFLAGS="-s -j 3"; \
		export QUIET_EXTRACTIONS=y; \
		eval `cat powerpc-405.dat $(CROSS_BUILD_VER).dat` LINUX_DIR=linux-2.6.12 bash all.sh --notest; \
		echo done
	# crosstool should do that, but it doesnt
	if [ ! -e $(CROSS_DIR)/$(TARGET)/include/mtd ]; then \
		cp -a $(BUILD_TMP)/crosstool-0.43/build/$(TARGET)/$(CROSS_BUILD_DIR)/linux-2.6.12/include/mtd $(CROSS_DIR)/$(TARGET)/include/;\
	fi

else
#
# $(TD_COMPILER) == new
$(CROSS_DIR)/bin/$(TARGET)-gcc: $(ARCHIVE)/crosstool-ng-1.20.0.tar.bz2 $(ARCHIVE)/linux-libc-headers-2.6.12.0.tar.bz2 $(ARCHIVE)/gcc-4.5.2.tar.bz2
	make $(BUILD_TMP)
	$(REMOVE)/crosstool-ng-1.20.0
	$(UNTAR)/crosstool-ng-1.20.0.tar.bz2
	$(UNTAR)/linux-libc-headers-2.6.12.0.tar.bz2
	ln -sf asm-ppc $(BUILD_TMP)//linux-libc-headers-2.6.12.0/include/asm
	set -e; unset CONFIG_SITE LD_LIBRARY_PATH; \
		if [ x`make --version | awk '/^GNU Make/{print int($$3)}'` != x3 ]; then \
			make $(BUILD_TMP)/bin/gmake; \
			export PATH=$(BUILD_TMP)/bin:$$PATH; \
		fi; \
		cd $(BUILD_TMP)/crosstool-ng-1.20.0; \
		cp -a $(PATCHES)/crosstool-ng-tripledragon.config .config; \
		test "$(GIT_PROTOCOL)" = http && \
			sed -i 's/^.*CT_EGLIBC_HTTP.*/CT_EGLIBC_HTTP=y/' .config || true; \
		NUM_CPUS=$$(expr `getconf _NPROCESSORS_ONLN` \* 2); \
		MEM_512M=$$(awk '/MemTotal/ {M=int($$2/1024/512); print M==0?1:M}' /proc/meminfo); \
		test $$NUM_CPUS -gt $$MEM_512M && NUM_CPUS=$$MEM_512M; \
		test $$NUM_CPUS = 0 && NUM_CPUS=1; \
		sed -i "s@^CT_PARALLEL_JOBS=.*@CT_PARALLEL_JOBS=$$NUM_CPUS@" .config; \
		export TD_BASE_DIR=$(BASE_DIR); \
		export TD_BUILD_TMP=$(BUILD_TMP); \
		V= ./configure --enable-local; \
		MAKELEVEL=0 make; \
		./ct-ng oldconfig; \
		./ct-ng build
	$(REMOVE)/crosstool-ng-1.20.0

endif
