#Makefile to build NEUTRINO

NEUTRINO_DEPS  = libcurl libid3tag libmad freetype libjpeg giflib ffmpeg libdvbsi++ libsigc++
NEUTRINO_DEPS += openthreads
NEUTRINO_DEPS += lua
NEUTRINO_PKG_DEPS =

N_CFLAGS   = -Wall -W -Wshadow -g -O2 -fno-strict-aliasing -rdynamic -DNEW_LIBCURL $(LOCAL_NEUTRINO_CFLAGS)
N_CPPFLAGS = -I$(TARGETPREFIX)/include
ifeq ($(PLATFORM), coolstream)
N_CPPFLAGS += -DUSE_NEVIS_GXA
endif
ifeq ($(PLATFORM), tripledragon)
N_CPPFLAGS += -I$(TARGETPREFIX)/include/hardware
# TODO: should we set this in a Header? Do we also need _D_LARGEFILE etc?
N_CPPFLAGS += -D_FILE_OFFSET_BITS=64
endif
ifeq ($(BOXARCH), sh4)
N_CFLAGS += -funsigned-char
endif
ifeq ($(BOXARCH), mipsel)
N_CFLAGS += -funsigned-char
endif

# choose between static and dynamic libtremor. As long as nothing else
# uses libtremor, static usage does not really hurt and is compatible
# with the "original" image
#N_CONFIG_OPTS = --with-tremor-static
N_CONFIG_OPTS = --with-tremor --disable-upnp
NEUTRINO_DEPS += libvorbisidec

# enable FLAC decoder in neutrino
N_CONFIG_OPTS += --enable-flac
NEUTRINO_DEPS += libFLAC

ifeq ($(USE_STB_HAL), yes)
N_CONFIG_OPTS += --with-stb-hal-includes=$(LH_SRC)/include \
	--with-stb-hal-build=$(LH_OBJDIR)
NEUTRINO_DEPS2 = libstb-hal
ifeq ($(PLATFORM), azbox)
# needed for forkpty() in libstb-hal/azbox/playback.cpp
N_CFLAGS += -lutil
NEUTRINO_PKG_DEPS += rmfp_player
endif
endif
ifeq ($(PLATFORM), spark)
# this is a hack: stfbcontrol triggers include/linux/stmfb.h,
# which is needed by framebuffer_spark
NEUTRINO_DEPS2 += $(TARGETPREFIX)/bin/stfbcontrol
endif
NEUTRINO_DEPS2 += $(TARGETPREFIX)/bin/fbshot

# the original build script links against openssl, but it is not needed at all.
# libcurl is picked up by configure anyway, so not needed here.
# N_LDFLAGS  = -L$(TARGETPREFIX)/lib -lcurl -lssl -lcrypto -ldl
N_LDFLAGS =
N_LDFLAGS += -Wl,-rpath-link,$(TARGETLIB)
N_LDFLAGS += -L$(TARGETLIB)

# finally we can build outside of the source directory
N_OBJDIR = $(BUILD_TMP)/$(FLAVOUR)
# use this if you want to build inside the source dir - but you don't want that ;)
# N_OBJDIR = $(N_HD_SOURCE)

$(N_OBJDIR)/config.status: $(NEUTRINO_DEPS) $(MAKE_DIR)/neutrino.mk
	test -d $(N_OBJDIR) || mkdir -p $(N_OBJDIR)
	$(N_HD_SOURCE)/autogen.sh
	set -e; cd $(N_OBJDIR); \
		CC=$(TARGET)-gcc CFLAGS="$(N_CFLAGS)" CXXFLAGS="$(N_CFLAGS)" CPPFLAGS="$(N_CPPFLAGS)" \
		LDFLAGS="$(N_LDFLAGS)" \
		$(N_HD_SOURCE)/configure --host=$(TARGET) --build=$(BUILD) --prefix= \
				--enable-silent-rules --enable-mdev --enable-giflib \
				--enable-maintainer-mode --with-target=cdk --with-boxtype=$(PLATFORM) \
				$(N_CONFIG_OPTS) $(LOCAL_NEUTRINO_BUILD_OPTIONS) \
				INSTALL="`which install` -p"; \
		test -e version.h || touch version.h


ifneq ($(FLAVOUR), neutrino-mp)
HOMEPAGE = "http://gitorious.org/neutrino-hd"
IMGNAME  = "HD-Neutrino"
else
HOMEPAGE = "http://gitorious.org/neutrino-mp"
IMGNAME  = "Neutrino-MP"
endif
$(PKGPREFIX)/.version \
$(TARGETPREFIX)/.version:
	echo "version=1200`date +%Y%m%d%H%M`"	 > $@
	echo "creator=$(MAINTAINER)"		>> $@
	echo "imagename=$(IMGNAME)"		>> $@
	A=$(FLAVOUR); F=$${A#neutrino-??}; \
		B=`cd $(N_HD_SOURCE); git describe --always --dirty`; \
		C=$${B%-dirty}; D=$${B#$$C}; \
		E=`cd $(N_HD_SOURCE); git tag --contains $$C`; \
		test -n "$$E" && C="$$E"; \
		echo "builddate=$$C$$D $${F:1}" >> $@
	echo "homepage=$(HOMEPAGE)"		>> $@
ifeq ($(USE_STB_HAL), yes)
	A=`cd $(LH_SRC); git describe --always --dirty`; \
		echo "libstbhalver=$$A" >> $@
endif

PHONY += $(PKGPREFIX)/.version $(TARGETPREFIX)/.version

$(D)/neutrino: $(N_OBJDIR)/config.status $(NEUTRINO_DEPS2)
	rm -f $(N_OBJDIR)/src/neutrino # trigger relinking, to pick up newly built libstb-hal
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	$(MAKE) -C $(N_OBJDIR) all     DESTDIR=$(TARGETPREFIX)
	$(MAKE) -C $(N_OBJDIR) install DESTDIR=$(TARGETPREFIX)
	+make $(TARGETPREFIX)/.version
	: touch $@

neutrino-pkg: $(N_OBJDIR)/config.status $(NEUTRINO_DEPS2) $(NEUTRINO_PKG_DEPS)
	rm -rf $(PKGPREFIX) $(BUILD_TMP)/neutrino-control
	$(MAKE) -C $(N_OBJDIR) clean   DESTDIR=$(TARGETPREFIX)
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	$(MAKE) -C $(N_OBJDIR) all     DESTDIR=$(TARGETPREFIX)
	$(MAKE) -C $(N_OBJDIR) install DESTDIR=$(PKGPREFIX)
	install -D -m 0755 skel-root/common/etc/init.d/start_neutrino $(PKGPREFIX)/etc/init.d/start_neutrino
	make $(PKGPREFIX)/.version
ifeq ($(USE_STB_HAL), yes)
	cp -a $(TARGETPREFIX)/bin/pic2m2v $(PKGPREFIX)/bin/
endif
	cp -a $(CONTROL_DIR)/$(NEUTRINO_PKG) $(BUILD_TMP)/neutrino-control
ifeq ($(PLATFORM), tripledragon)
	grep -q /dev/dvb/adapter%d/frontend%d $(PKGPREFIX)/bin/neutrino && \
		sed -i "s/\(@DEP@\)/td-dvb-frontend.ko, uinput.ko, evdev.ko, \1/" $(BUILD_TMP)/neutrino-control/control
endif
	DEP=`$(TARGET)-objdump -p $(PKGPREFIX)/bin/neutrino | awk '/NEEDED/{print $$2}' | sort` && \
		DEP=`echo $$DEP` && \
		DEP="$${DEP// /, }" && \
		sed -i "s/@DEP@/$$DEP/" $(BUILD_TMP)/neutrino-control/control
ifeq ($(PLATFORM), coolstream)
	sed -i 's/^\(Depends:.*\)$$/\1, cs-drivers/' $(BUILD_TMP)/neutrino-control/control
endif
ifeq ($(PLATFORM), azbox)
	sed -i 's/^\(Depends:.*\)$$/\1, azboxme-dvb-drivers, rmfp_player/' $(BUILD_TMP)/neutrino-control/control
endif
	install -p -m 0755 $(TARGETPREFIX)/bin/fbshot $(PKGPREFIX)/bin/
	find $(PKGPREFIX)/share/tuxbox/neutrino/locale/ -type f \
		! -name deutsch.locale ! -name english.locale | xargs --no-run-if-empty rm
	# ignore the .version file for package  comparison
	DONT_STRIP=$(NEUTRINO_NOSTRIP) CMP_IGNORE="/.version" $(OPKG_SH) $(BUILD_TMP)/neutrino-control
	rm -rf $(PKGPREFIX)

neutrino-clean:
	-make -C $(N_OBJDIR) uninstall
	-make -C $(N_OBJDIR) distclean
	-rm $(N_OBJDIR)/config.status
	-rm $(D)/neutrino

PHONY += neutrino-clean neutrino-system neutrino-system-seife

LH_DEPS =
ifeq ($(PLATFORM), spark)
LH_DEPS += libass ffmpeg | stfbcontrol
endif
LH_OBJDIR = $(BUILD_TMP)/libstb-hal
LH_SRC = $(SOURCE_DIR)/libstb-hal
$(LH_OBJDIR)/config.status: $(MAKE_DIR)/neutrino.mk $(LH_DEPS)
	test -d $(LH_OBJDIR) || mkdir -p $(LH_OBJDIR)
	$(LH_SRC)/autogen.sh
	set -e; cd $(LH_OBJDIR); \
		export PKG_CONFIG=$(PKG_CONFIG); \
		export PKG_CONFIG_PATH=$(PKG_CONFIG_PATH); \
		CC=$(TARGET)-gcc CFLAGS="$(N_CFLAGS)" CXXFLAGS="$(N_CFLAGS)" CPPFLAGS="$(N_CPPFLAGS)" \
		LDFLAGS="$(N_LDFLAGS) -L$(TARGETLIB)" \
		$(LH_SRC)/configure --host=$(TARGET) --build=$(BUILD) --prefix= \
				--enable-maintainer-mode --with-target=cdk --with-boxtype=$(PLATFORM) \
				--enable-silent-rules \
				INSTALL="`which install` -p"

libstb-hal: $(LH_OBJDIR)/config.status
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	$(MAKE) -C $(LH_OBJDIR) all     DESTDIR=$(TARGETPREFIX)
	$(MAKE) -C $(LH_OBJDIR) install DESTDIR=$(TARGETPREFIX)
