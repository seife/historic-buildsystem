# Makefile to build system libs, potentially needed by neutrino and enigma

$(D)/zlib: $(ARCHIVE)/zlib-$(ZLIB_VER).tar.bz2 | $(TARGETPREFIX)
	$(UNTAR)/zlib-$(ZLIB_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/zlib-$(ZLIB_VER); \
		CC=$(TARGET)-gcc mandir=$(BUILD_TMP)/.remove ./configure --prefix= --shared; \
		$(MAKE); \
		ln -sf /bin/true ldconfig; \
		rm -f $(TARGETPREFIX)/lib/libz.so*; \
		PATH=$(BUILD_TMP)/zlib-$(ZLIB_VER):$(PATH) make install prefix=$(TARGETPREFIX)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/zlib.pc
	$(REMOVE)/zlib-$(ZLIB_VER) $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/lib/libz.so.* $(PKGPREFIX)/lib
	PKG_VER=$(ZLIB_VER) $(OPKG_SH) $(CONTROL_DIR)/libz
	$(REMOVE)/.remove $(PKGPREFIX)
	touch $@

$(D)/libblkid: $(D)/libuuid
$(D)/libuuid: $(ARCHIVE)/util-linux-ng-$(UTIL_LINUX_NG_VER).tar.bz2 | $(TARGETPREFIX)
	$(UNTAR)/util-linux-ng-$(UTIL_LINUX_NG_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/util-linux-ng-$(UTIL_LINUX_NG_VER); \
		$(CONFIGURE) --prefix= \
			--disable-libmount \
			--disable-static \
			--without-ncurses \
			--mandir=/.remove; \
		$(MAKE) -C shlibs; \
		$(MAKE) -C shlibs install DESTDIR=$(TARGETPREFIX)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/uuid.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/blkid.pc
	rm -rf $(TARGETPREFIX)/.remove
	$(REMOVE)/util-linux-ng-$(UTIL_LINUX_NG_VER)
	rm -fr $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/lib/libblkid.so.{1,1.1.0} $(PKGPREFIX)/lib
	$(OPKG_SH) $(CONTROL_DIR)/util-linux/libblkid
	rm $(PKGPREFIX)/lib/*
	cp -a $(TARGETPREFIX)/lib/libuuid.so.{1,1.3.0} $(PKGPREFIX)/lib
	$(OPKG_SH) $(CONTROL_DIR)/util-linux/libuuid
	rm -rf $(PKGPREFIX)
	touch $(D)/libuuid $(D)/libblkid

ifeq ($(BOXARCH), arm)
MAD_FPM = arm
else
ifeq ($(BOXARCH), powerpc)
MAD_FPM = ppc
else
MAD_FPM = default
endif
endif
$(D)/libmad: $(ARCHIVE)/libmad-$(MAD_VER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/libmad-$(MAD_VER).tar.gz
	set -e; cd $(BUILD_TMP)/libmad-$(MAD_VER); \
		patch -p1 < $(PATCHES)/libmad.diff; \
		patch -p1 < $(PATCHES)/libmad-$(MAD_VER)-arm-buildfix.diff; \
		touch NEWS AUTHORS ChangeLog; \
		autoreconf -fi; \
		$(CONFIGURE) --prefix= --enable-shared=yes --enable-speed --enable-fpm=$(MAD_FPM) --enable-sso; \
		$(MAKE) all; \
		make install DESTDIR=$(TARGETPREFIX); \
		sed "s!^prefix=.*!prefix=$(TARGETPREFIX)!;" mad.pc > $(PKG_CONFIG_PATH)/libmad.pc
	$(REWRITE_LIBTOOL)/libmad.la
	$(REMOVE)/libmad-$(MAD_VER) $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/lib/libmad.so.* $(PKGPREFIX)/lib
	$(OPKG_SH) $(CONTROL_DIR)/libmad
	rm -rf $(PKGPREFIX)
	touch $@

$(D)/libid3tag: $(D)/zlib $(ARCHIVE)/libid3tag-$(ID3TAG_VER)$(ID3TAG_SUBVER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/libid3tag-$(ID3TAG_VER)$(ID3TAG_SUBVER).tar.gz
	set -e; cd $(BUILD_TMP)/libid3tag-$(ID3TAG_VER)$(ID3TAG_SUBVER); \
		patch -p1 < $(PATCHES)/libid3tag.diff; \
		$(CONFIGURE) --prefix= --build=$(BUILD) --host=$(TARGET) --enable-shared=yes; \
		$(MAKE) all; \
		make install DESTDIR=$(TARGETPREFIX); \
		sed "s!^prefix=.*!prefix=$(TARGETPREFIX)!;" id3tag.pc > $(PKG_CONFIG_PATH)/libid3tag.pc
	$(REWRITE_LIBTOOL)/libid3tag.la
	$(REMOVE)/libid3tag-$(ID3TAG_VER)$(ID3TAG_SUBVER) $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/lib/libid3tag.so.* $(PKGPREFIX)/lib
	$(OPKG_SH) $(CONTROL_DIR)/libid3tag
	rm -rf $(PKGPREFIX)
	touch $@

# obsoleted by giflib, but might still be needed by some 3rd party binaries
# to make sure it is not used to build stuff, it is not installed in TARGETPREFIX
$(D)/libungif: $(ARCHIVE)/libungif-$(UNGIF_VER).tar.bz2
	rm -rf $(PKGPREFIX)
	$(UNTAR)/libungif-$(UNGIF_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/libungif-$(UNGIF_VER); \
		$(CONFIGURE) --prefix= --build=$(BUILD) --host=$(TARGET) --without-x --bindir=/.remove; \
		$(MAKE) all; \
		make install DESTDIR=$(PKGPREFIX)
	rm -rf $(PKGPREFIX)/.remove $(PKGPREFIX)/include $(PKGPREFIX)/lib/libungif.?? $(PKGPREFIX)/lib/libungif.a
	$(OPKG_SH) $(CONTROL_DIR)/libungif
	$(REMOVE)/libungif-$(UNGIF_VER) $(PKGPREFIX)
	touch $@

$(D)/giflib: $(D)/giflib-$(GIFLIB_VER)
	touch $@
$(D)/giflib-$(GIFLIB_VER): $(ARCHIVE)/giflib-$(GIFLIB_VER).tar.bz2 | $(TARGETPREFIX)
	$(UNTAR)/giflib-$(GIFLIB_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/giflib-$(GIFLIB_VER); \
		export ac_cv_prog_have_xmlto=no; \
		$(CONFIGURE) --prefix= --build=$(BUILD) --host=$(TARGET) --bindir=/.remove; \
		$(MAKE) all; \
		make install DESTDIR=$(TARGETPREFIX); \
	$(REWRITE_LIBTOOL)/libgif.la
	rm -rf $(TARGETPREFIX)/.remove
	$(REMOVE)/giflib-$(GIFLIB_VER) $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/lib/libgif.so.* $(PKGPREFIX)/lib
	PKG_VER=$(GIFLIB_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/giflib
	rm -rf $(PKGPREFIX)
	touch $@

$(D)/libcurl: $(D)/libcurl-$(CURL_VER)
	touch $@
$(D)/libcurl-$(CURL_VER): $(ARCHIVE)/curl-$(CURL_VER).tar.bz2 $(D)/zlib | $(TARGETPREFIX)
	$(UNTAR)/curl-$(CURL_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/curl-$(CURL_VER); \
		$(CONFIGURE) --prefix= --build=$(BUILD) --host=$(TARGET) \
			--disable-manual --disable-file --disable-rtsp --disable-dict \
			--disable-imap --disable-pop3 --disable-smtp --without-ssl \
			--with-random --mandir=/.remove; \
		$(MAKE) all; \
		mkdir -p $(HOSTPREFIX)/bin; \
		sed -e "s,^prefix=,prefix=$(TARGETPREFIX)," < curl-config > $(HOSTPREFIX)/bin/curl-config; \
		chmod 755 $(HOSTPREFIX)/bin/curl-config; \
		make install DESTDIR=$(PKGPREFIX)
	rm $(PKGPREFIX)/bin/curl-config
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	$(REMOVE)/pkg-lib; mkdir $(BUILD_TMP)/pkg-lib
	cd $(PKGPREFIX) && rm -r include lib/pkgconfig lib/*.so lib/*a .remove/ && mv lib $(BUILD_TMP)/pkg-lib
	PKG_VER=$(CURL_VER) $(OPKG_SH) $(CONTROL_DIR)/curl/curl
	rm -rf $(PKGPREFIX)/*
	mv $(BUILD_TMP)/pkg-lib/* $(PKGPREFIX)/
	PKG_VER=$(CURL_VER) $(OPKG_SH) $(CONTROL_DIR)/curl/libcurl
	$(REWRITE_LIBTOOL)/libcurl.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libcurl.pc
	rm -rf $(TARGETPREFIX)/.remove
	$(REMOVE)/curl-$(CURL_VER) $(PKGPREFIX) $(BUILD_TMP)/pkg-lib
	touch $@

# no Package, since it's only linked statically for now also only install static lib
$(D)/libFLAC: $(ARCHIVE)/flac-1.2.1.tar.gz | $(TARGETPREFIX)
	$(UNTAR)/flac-1.2.1.tar.gz
	set -e; cd $(BUILD_TMP)/flac-1.2.1; \
		$(PATCH)/flac-1.2.1-noencoder.diff; \
		$(CONFIGURE) --prefix= --build=$(BUILD) --host=$(TARGET) \
			--disable-ogg --disable-altivec; \
		$(MAKE) -C src/libFLAC; \
		: make -C src/libFLAC  install DESTDIR=$(TARGETPREFIX); \
		cp -a src/libFLAC/.libs/libFLAC.a $(TARGETPREFIX)/lib/; \
		make -C include/FLAC install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/flac-1.2.1
	touch $@

# hackedy hack :-)
space :=
space +=
PNG_SOVER = $(subst $(space),, $(wordlist 1, 2, $(subst ., , $(PNG_VER))))
$(D)/libpng: $(D)/libpng-$(PNG_VER)
	touch $@
$(D)/libpng-$(PNG_VER): $(ARCHIVE)/libpng-$(PNG_VER).tar.xz $(D)/zlib | $(TARGETPREFIX)
	$(UNTAR)/libpng-$(PNG_VER).tar.xz
	set -e; cd $(BUILD_TMP)/libpng-$(PNG_VER); \
		$(CONFIGURE) --prefix=$(TARGETPREFIX) --build=$(BUILD) --host=$(TARGET) --bindir=$(HOSTPREFIX)/bin --mandir=$(BUILD_TMP)/tmpman; \
		ECHO=echo $(MAKE) all; \
		rm -f $(TARGETPREFIX)/lib/libpng.so* $(TARGETPREFIX)/lib/libpng$(PNG_SOVER).so*; \
		make install
	$(REMOVE)/libpng-$(PNG_VER) $(BUILD_TMP)/tmpman $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/lib/libpng$(PNG_SOVER).so.* $(PKGPREFIX)/lib
	PKG_VER=$(PNG_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/libpng$(PNG_SOVER)
	rm -rf $(PKGPREFIX)
	touch $@

$(D)/freetype: $(D)/freetype-$(FREETYPE_VER)
	touch $@
$(D)/freetype-$(FREETYPE_VER): $(D)/libpng $(ARCHIVE)/freetype-$(FREETYPE_VER).tar.bz2 | $(TARGETPREFIX)
	$(REMOVE)/freetype-$(FREETYPE_VER)
	$(UNTAR)/freetype-$(FREETYPE_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/freetype-$(FREETYPE_VER); \
		if ! echo $(FREETYPE_VER) | grep "2.3"; then \
			patch -p1 -i $(PATCHES)/freetype_2.5_render_old.diff; \
			patch -p1 -i $(PATCHES)/freetype_2.5_subpix_hint.diff; \
		fi; \
		sed -i '/#define FT_CONFIG_OPTION_OLD_INTERNALS/d' include/freetype/config/ftoption.h; \
		sed -i '/^FONT_MODULES += \(type1\|cid\|pfr\|type42\|pcf\|bdf\)/d' modules.cfg; \
		$(CONFIGURE) --prefix=$(TARGETPREFIX) --build=$(BUILD) --host=$(TARGET); \
		$(MAKE) all; \
		rm -f $(TARGETPREFIX)/lib/libfreetype.so*; \
		make install; \
		if [ -d $(TARGETPREFIX)/include/freetype2/freetype ] ; then \
			ln -sf ./freetype2/freetype $(TARGETPREFIX)/include/freetype; \
		fi;
	mv $(TARGETPREFIX)/bin/freetype-config $(HOSTPREFIX)/bin/freetype-config
	$(REMOVE)/freetype-$(FREETYPE_VER) $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/lib/libfreetype.so.* $(PKGPREFIX)/lib
	PKG_VER=$(FREETYPE_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/libfreetype
	rm -rf $(PKGPREFIX)
	touch $@

## build both libjpeg.so.62 and libjpeg.so.8
## use only libjpeg.so.62 for our own build, but keep libjpeg8 for
## compatibility to third party binaries
$(D)/libjpeg: $(D)/libjpeg-turbo-$(JPEG_TURBO_VER)
	touch $@
$(D)/libjpeg-turbo-$(JPEG_TURBO_VER): $(ARCHIVE)/libjpeg-turbo-$(JPEG_TURBO_VER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/libjpeg-turbo-$(JPEG_TURBO_VER).tar.gz
	set -e; cd $(BUILD_TMP)/libjpeg-turbo-$(JPEG_TURBO_VER); \
		export CC=$(TARGET)-gcc; \
		$(CONFIGURE) --prefix= --build=$(BUILD) --host=$(TARGET) --enable-shared \
			--mandir=/.remove --bindir=/.remove \
			--with-jpeg8 --disable-static --includedir=/.remove ; \
		$(MAKE) ; \
		make install DESTDIR=$(TARGETPREFIX); \
		make clean; \
		$(CONFIGURE) --prefix= --build=$(BUILD) --host=$(TARGET) --enable-shared \
			--mandir=/.remove --bindir=/.remove ; \
		$(MAKE) ; \
		make install DESTDIR=$(TARGETPREFIX)
	$(REWRITE_LIBTOOL)/libjpeg.la
	rm -f $(TARGETPREFIX)/lib/libturbojpeg* $(TARGETPREFIX)/include/turbojpeg.h
	$(REMOVE)/libjpeg-turbo-$(JPEG_TURBO_VER) $(TARGETPREFIX)/.remove $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/lib/libjpeg.so.* $(PKGPREFIX)/lib
	PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		PKG_VER=$(JPEG_TURBO_VER) $(OPKG_SH) $(CONTROL_DIR)/libjpeg
	rm -rf $(PKGPREFIX)
	touch $@

$(D)/libboost: $(ARCHIVE)/boost_$(BOOST_VER).tar.bz2 | $(TARGETPREFIX)
	set -e; cd $(BUILD_TMP); \
		tar xf $(ARCHIVE)/boost_$(BOOST_VER).tar.bz2 boost_$(BOOST_VER)/boost; \
		rm -rf $(TARGETPREFIX)/include/boost;\
		mv boost_$(BOOST_VER)/boost $(TARGETPREFIX)/include/boost; \
		rmdir boost_$(BOOST_VER)
	touch $@

# openssl seems to have problem with parallel builds, so use "make" instead of "$(MAKE)"
$(D)/openssl: $(ARCHIVE)/openssl-$(OPENSSL_VER)$(OPENSSL_SUBVER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/openssl-$(OPENSSL_VER)$(OPENSSL_SUBVER).tar.gz
	set -e; cd $(BUILD_TMP)/openssl-$(OPENSSL_VER)$(OPENSSL_SUBVER); \
		sed -i 's/#define DATE.*/#define DATE \\"($(PLATFORM))\\""; \\/' crypto/Makefile; \
		CC=$(TARGET)-gcc \
		./Configure shared no-hw no-engine linux-generic32 --prefix=/ --openssldir=/.remove; \
		make depend; \
		make all; \
		make install_sw INSTALL_PREFIX=$(TARGETPREFIX)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/openssl.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libcrypto.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libssl.pc
	rm -r $(TARGETPREFIX)/.remove $(TARGETPREFIX)/bin/openssl $(TARGETPREFIX)/bin/c_rehash
	$(REMOVE)/openssl-$(OPENSSL_VER)$(OPENSSL_SUBVER)
	chmod 0755 $(TARGETPREFIX)/lib/libcrypto.so.* $(TARGETPREFIX)/lib/libssl.so.*
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/lib/lib{crypto,ssl}.so.$(OPENSSL_VER) $(PKGPREFIX)/lib
	$(OPKG_SH) $(CONTROL_DIR)/openssl-libs
	rm -rf $(PKGPREFIX)
	touch $@

ifeq ($(BOXARCH), arm)
FFMPEG_CONFIGURE  = --arch=arm --cpu=armv6 --disable-neon
FFMPEG_CONFIGURE += --disable-decoders --disable-parsers --disable-demuxers
FFMPEG_CONFIGURE += --disable-ffmpeg --disable-swscale --disable-filters --enable-swresample --disable-postproc
FFMPEG_CONFIGURE += --enable-parser=aac --enable-parser=aac_latm --enable-parser=ac3 --enable-parser=dca
FFMPEG_CONFIGURE += --enable-parser=mpeg4video --enable-parser=mpegvideo --enable-parser=mpegaudio
FFMPEG_CONFIGURE += --enable-parser=h264 --enable-parser=vc1 --enable-parser=dvdsub --enable-parser=dvbsub
FFMPEG_CONFIGURE += --enable-decoder=dca --enable-decoder=dvdsub --enable-decoder=dvbsub
FFMPEG_CONFIGURE += --enable-decoder=text --enable-decoder=srt --enable-decoder=subrip
FFMPEG_CONFIGURE += --enable-decoder=subviewer --enable-decoder=subviewer1
FFMPEG_CONFIGURE += --enable-decoder=xsub --enable-decoder=pgssub
FFMPEG_CONFIGURE += --enable-demuxer=aac --enable-demuxer=ac3
FFMPEG_CONFIGURE += --enable-demuxer=avi --enable-demuxer=mov --enable-demuxer=vc1
FFMPEG_CONFIGURE += --enable-demuxer=mpegts --enable-demuxer=mpegtsraw --enable-demuxer=mpegps
FFMPEG_CONFIGURE += --enable-demuxer=mpegvideo --enable-demuxer=wav --enable-demuxer=pcm_s16be
FFMPEG_CONFIGURE += --enable-demuxer=mp3 --enable-demuxer=pcm_s16le --enable-demuxer=matroska
FFMPEG_CONFIGURE += --enable-demuxer=flv --enable-demuxer=rm
FFMPEG_CONFIGURE += --enable-network --enable-protocol=http
FFMPEG_CONFIGURE += --enable-demuxer=rtsp
FFMPEG_CONFIGURE += --enable-protocol=rtmp --enable-protocol=rtmpe --enable-protocol=rtmps --enable-protocol=rtmpte --enable-protocol=rtp
FFMPEG_CONFIGURE += --enable-bsfs
endif
ifeq ($(BOXARCH), powerpc)
FFMPEG_CONFIGURE  = --arch=ppc
FFMPEG_CONFIGURE += --disable-decoders
FFMPEG_CONFIGURE += --disable-parsers --disable-demuxers --enable-ffmpeg
FFMPEG_CONFIGURE += --enable-parser=mjpeg --enable-demuxer=mjpeg --enable-decoder=mjpeg
FFMPEG_CONFIGURE += --enable-encoder=mpeg2video --enable-muxer=mpeg2video
FFMPEG_CONFIGURE += --disable-bsfs
FFMPEG_CONFIGURE += --disable-network
FFMPEG_CONFIGURE += --enable-dct
endif
## todo: check. this is a plain copy of tripledragon configure...
ifeq ($(BOXARCH), sh4)
FFMPEG_CONFIGURE  = --arch=sh4
FFMPEG_CONFIGURE += --enable-ffmpeg --enable-demuxers
FFMPEG_CONFIGURE += --enable-parser=mjpeg --enable-demuxer=mjpeg --enable-decoder=mjpeg
FFMPEG_CONFIGURE += --enable-encoder=mpeg2video --enable-muxer=mpeg2video
FFMPEG_CONFIGURE += --disable-bsfs
FFMPEG_CONFIGURE += --disable-network
endif
ifeq ($(BOXARCH), mipsel)
FFMPEG_CONFIGURE  = --arch=mips
FFMPEG_CONFIGURE += --enable-ffmpeg --enable-demuxers
FFMPEG_CONFIGURE += --enable-parser=mjpeg --enable-demuxer=mjpeg --enable-decoder=mjpeg
FFMPEG_CONFIGURE += --enable-encoder=mpeg2video --enable-muxer=mpeg2video
FFMPEG_CONFIGURE += --disable-bsfs
FFMPEG_CONFIGURE += --disable-network
endif
$(D)/ffmpeg: $(D)/ffmpeg-$(FFMPEG_VER)
	touch $@
$(D)/ffmpeg-$(FFMPEG_VER): $(ARCHIVE)/ffmpeg-$(FFMPEG_VER).tar.bz2 | $(TARGETPREFIX)
ifeq ($(PLATFORM), coolstream)
	if ! test -d $(UNCOOL_GIT)/cst-public-libraries-ffmpeg; then \
		make $(UNCOOL_GIT)/cst-public-libraries-ffmpeg; \
	fi
	rm -rf $(BUILD_TMP)/ffmpeg-$(FFMPEG_VER)
	cp -a $(UNCOOL_GIT)/cst-public-libraries-ffmpeg $(BUILD_TMP)/ffmpeg-$(FFMPEG_VER)
else
	$(UNTAR)/ffmpeg-$(FFMPEG_VER).tar.bz2
endif
	set -e; cd $(BUILD_TMP)/ffmpeg-$(FFMPEG_VER); \
		sed -i '/\(__DATE__\|__TIME__\)/d' ffprobe.c; # remove build time \
		sed -i -e 's/__DATE__/""/' -e 's/__TIME__/""/' cmdutils.c; \
		./configure \
			--disable-encoders \
			--disable-muxers --disable-ffplay --disable-ffserver \
			--disable-protocols \
			$(FFMPEG_CONFIGURE) \
			--enable-decoder=dvbsub --enable-demuxer=mpegps \
			--disable-devices --disable-mmx --disable-altivec \
			--enable-protocol=file \
			--disable-zlib --enable-bzlib \
			--disable-ffprobe \
			--disable-static --enable-shared \
			--enable-cross-compile \
			--cross-prefix=$(TARGET)- \
			--target-os=linux \
			--enable-debug --enable-stripping \
			--disable-doc \
			--prefix=/; \
		$(MAKE); \
		make install DESTDIR=$(PKGPREFIX)
	rm -rf $(PKGPREFIX)/share/ffmpeg
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	cp $(BUILD_TMP)/ffmpeg-$(FFMPEG_VER)/version.h $(TARGETPREFIX)/lib/ffmpeg-version.h
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libavfilter.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libavdevice.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libavformat.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libavcodec.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libavutil.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libswresample.pc
	test -e $(PKG_CONFIG_PATH)/libswscale.pc && $(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libswscale.pc || true
	rm -rf $(PKGPREFIX)/include $(PKGPREFIX)/lib/pkgconfig $(PKGPREFIX)/lib/*.so $(PKGPREFIX)/.remove
	PKG_VER=$(FFMPEG_VER) PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/ffmpeg
	$(REMOVE)/ffmpeg-$(FFMPEG_VER) $(PKGPREFIX)
	touch $@

$(D)/libass: $(ARCHIVE)/libass-$(LIBASS_VER).tar.gz $(D)/freetype| $(TARGETPREFIX)
	$(UNTAR)/libass-$(LIBASS_VER).tar.gz
	set -e; cd $(BUILD_TMP)/libass-$(LIBASS_VER); \
		$(CONFIGURE) --disable-fontconfig --prefix= --disable-shared; \
		$(MAKE); \
		make install DESTDIR=$(TARGETPREFIX)
	$(REWRITE_LIBTOOL)/libass.la
	touch $@

$(D)/libogg: $(ARCHIVE)/libogg-$(OGG_VER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/libogg-$(OGG_VER).tar.gz
	set -e; cd $(BUILD_TMP)/libogg-$(OGG_VER); \
		$(CONFIGURE) --prefix= --enable-shared; \
		$(MAKE); \
		make install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/share/doc
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/ogg.pc
	$(REWRITE_LIBTOOL)/libogg.la
	set -e; cd $(PKGPREFIX); rm -rf share include lib/pkgconfig; rm lib/*a lib/*.so
	PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		PKG_VER=$(OGG_VER) $(OPKG_SH) $(CONTROL_DIR)/libogg
	$(REMOVE)/libogg-$(OGG_VER) $(PKGPREFIX)
	touch $@

$(D)/libvorbis: $(D)/libogg $(ARCHIVE)/libvorbis-$(VORBIS_VER).tar.xz | $(TARGETPREFIX)
	$(UNTAR)/libvorbis-$(VORBIS_VER).tar.xz
	set -e; cd $(BUILD_TMP)/libvorbis-$(VORBIS_VER); \
		$(CONFIGURE) --enable-shared --prefix= LDFLAGS="-Wl,-rpath-link,$(TARGETLIB)" CFLAGS="$(TARGET_CFLAGS)"; \
		$(MAKE); \
		make install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/share/doc
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/vorbis.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/vorbisenc.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/vorbisfile.pc
	$(REWRITE_LIBTOOL)/libvorbis.la
	$(REWRITE_LIBTOOL)/libvorbisenc.la
	$(REWRITE_LIBTOOL)/libvorbisfile.la
	sed -i '/^dependency_libs=/{ s# /lib# $(TARGETPREFIX)/lib#g }' $(TARGETPREFIX)/lib/libvorbis*.la
	set -e; cd $(PKGPREFIX); rm -rf share include lib/pkgconfig; rm lib/*a lib/*.so
	PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		PKG_VER=$(VORBIS_VER) $(OPKG_SH) $(CONTROL_DIR)/libvorbis
	$(REMOVE)/libvorbis-$(VORBIS_VER) $(PKGPREFIX)
	touch $@

ncurses-prereq:
	@if $(MAKE) find-tic find-infocmp ; then \
		true; \
	else \
		echo "**********************************************************"; \
		echo "* tic or infocmp missing, but needed to build libncurses *"; \
		echo "* install the ncurses development package on your system *"; \
		echo "**********************************************************"; \
		false; \
	fi

$(D)/libncurses: $(ARCHIVE)/ncurses-$(NCURSES_VER).tar.gz | ncurses-prereq $(TARGETPREFIX)
	$(UNTAR)/ncurses-$(NCURSES_VER).tar.gz
	set -e; cd $(BUILD_TMP)/ncurses-$(NCURSES_VER); \
		$(CONFIGURE) --build=$(BUILD) --host=$(TARGET) --target=$(TARGET) \
			--prefix= --with-terminfo-dirs=/usr/share/terminfo \
			--disable-big-core --without-debug --without-progs --without-ada --with-shared \
			--without-profile --disable-rpath --without-cxx-binding \
			--with-fallbacks='linux vt100 xterm'; \
		$(MAKE) libs HOSTCC=gcc HOSTLDFLAGS="$(TARGET_LDFLAGS)" \
			HOSTCCFLAGS="$(TARGET_CFLAGS) -DHAVE_CONFIG_H -I../ncurses -DNDEBUG -D_GNU_SOURCE -I../include"; \
		make install.libs DESTDIR=$(TARGETPREFIX); \
		install -D -m 0755 misc/ncurses-config $(HOSTPREFIX)/bin/ncurses5-config
	$(REMOVE)/ncurses-$(NCURSES_VER) $(PKGPREFIX)
	$(REWRITE_PKGCONF) $(HOSTPREFIX)/bin/ncurses5-config
	mkdir -p $(PKGPREFIX)/lib
	# deliberately ignore libforms and libpanel - not yet needed
	cp -a $(TARGETPREFIX)/lib/libncurses.so.* $(PKGPREFIX)/lib
	$(OPKG_SH) $(CONTROL_DIR)/libncurses
	rm -rf $(PKGPREFIX)
	touch $@

# this is butt ugly. For some reason, the old libtool in debian lenny 5.0.7
# does not put "-lz" into LDFLAGS of some subdirs, and I was not able to fix that.
# Hence the LDFLAGS="$(TARGET_LDFLAGS) -lz" hack... :-(
$(D)/directfb: $(ARCHIVE)/DirectFB-$(DIRECTFB_VER).tar.gz $(D)/zlib $(D)/freetype $(D)/libpng $(D)/libjpeg | $(TARGETPREFIX) $(HOSTPREFIX)/bin
	rm -rf $(PKGPREFIX)
	$(UNTAR)/DirectFB-$(DIRECTFB_VER).tar.gz
	set -e; cd $(BUILD_TMP)/DirectFB-$(DIRECTFB_VER); \
		gzip -dc $(PATCHES)/coolstream/directfb-1.4.3-coolstream.diff | patch -p2; \
		patch -p1 -i $(PATCHES)/directfb-1.4.3-cx245x-deinit-restore-fix.diff; \
		sed -i 's/"-DBUILDTIME=.*/"-DBUILDTIME=\\"($(PLATFORM))\\""/' src/core/Makefile.am; \
		./autogen.sh fail || true ; \
		CFLAGS="$(TARGET_CFLAGS)" CPPFLAGS="$(TARGET_CPPFLAGS)" \
			CXXFLAGS="$(TARGET_CXXFLAGS)" PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			LDFLAGS="$(TARGET_LDFLAGS) -lz" \
			./configure \
			--prefix=/ --mandir=/.remove --bindir=/opt/pkg/bin \
			--build=$(BUILD) --host=$(TARGET) \
			--with-inputdrivers=linuxinput,keyboard,ps2mouse \
			--with-gfxdrivers=cx2450x --disable-video4linux \
			--disable-video4linux2 --enable-zlib --disable-x11 --disable-osx --disable-vnc \
			--enable-debug --disable-network --disable-devmem --disable-sysfs --enable-fbdev \
			--enable-jpeg --with-tests; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX); \
		cp -a directfb-config $(HOSTPREFIX)/bin/
	mkdir $(PKGPREFIX)/etc
	printf 'mode "1280x720-50"\n    geometry 1280 720 1280 720 32\n    timings 0 0 0 0 0 0 0\nendmode\n' > $(PKGPREFIX)/etc/fb.modes
	printf 'system=cx2450x\nlinux-input-devices=/dev/input/nevis_ir\nno-linux-input-grab\nmode=1280x720\npixelformat=ARGB\nbg-color=00000000\nno-debug\nautoflip-window\nno-cursor\n' > $(PKGPREFIX)/etc/directfbrc
	rm -fr $(PKGPREFIX)/.remove $(PKGPREFIX)/opt/pkg/bin/directfb-config
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)/
	find $(PKGPREFIX) -name '*.la' | xargs --no-run-if-empty rm
	rm -fr $(PKGPREFIX)/include $(PKGPREFIX)/lib/pkgconfig $(PKGPREFIX)/lib/*.so
	$(REMOVE)/dfb-tmp
	mkdir $(BUILD_TMP)/dfb-tmp
	mv $(PKGPREFIX)/opt $(BUILD_TMP)/dfb-tmp
	$(OPKG_SH) $(CONTROL_DIR)/cs-directfb/libdirectfb
	rm -rf $(PKGPREFIX)/*
	mv $(BUILD_TMP)/dfb-tmp/opt $(PKGPREFIX)
	rmdir $(BUILD_TMP)/dfb-tmp
	$(OPKG_SH) $(CONTROL_DIR)/cs-directfb/directfb-tools
	$(REMOVE)/DirectFB-$(DIRECTFB_VER) $(PKGPREFIX)
	touch $@

# the strange find | sed hack is needed for old cmake versions which
# don't obey CMAKE_INSTALL_PREFIX (e.g. debian lenny 5.0.7's cmake 2.6)
$(D)/openthreads: | $(TARGETPREFIX) find-lzma
	lzma -dc $(PATCHES)/sources/OpenThreads-svn-13083.tar.lzma | tar -C $(BUILD_TMP) -x
	set -e; cd $(BUILD_TMP)/OpenThreads-svn-13083; \
		rm CMakeFiles/* -rf CMakeCache.txt cmake_install.cmake; \
		cmake . -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_NAME="Linux" \
			-DCMAKE_INSTALL_PREFIX="" \
			-DCMAKE_C_COMPILER="$(TARGET)-gcc" \
			-DCMAKE_CXX_COMPILER="$(TARGET)-g++" \
			-D_OPENTHREADS_ATOMIC_USE_GCC_BUILTINS_EXITCODE=1; \
		find . -name cmake_install.cmake -print0 | xargs -0 \
			sed -i 's@SET(CMAKE_INSTALL_PREFIX "/usr/local")@SET(CMAKE_INSTALL_PREFIX "")@'; \
		$(MAKE); \
		make install DESTDIR=$(TARGETPREFIX)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/openthreads.pc
	$(REMOVE)/OpenThreads-svn-13083 $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/lib/libOpenThreads.so.* $(PKGPREFIX)/lib
	PKG_VER=13083 $(OPKG_SH) $(CONTROL_DIR)/libOpenThreads
	rm -rf $(PKGPREFIX)
	touch $@

$(D)/libvorbisidec: $(D)/libvorbisidec-$(VORBISIDEC_VER)
	touch $@
$(D)/libvorbisidec-$(VORBISIDEC_VER): $(ARCHIVE)/libvorbisidec_$(VORBISIDEC_VER)$(VORBISIDEC_VER_APPEND).tar.gz $(D)/libogg
	$(UNTAR)/libvorbisidec_$(VORBISIDEC_VER)$(VORBISIDEC_VER_APPEND).tar.gz
	set -e; cd $(BUILD_TMP)/libvorbisidec-$(VORBISIDEC_VER); \
		patch -p1 < $(PATCHES)/tremor.diff; \
		ACLOCAL_FLAGS="-I . -I $(TARGETPREFIX)/share/aclocal" \
		$(BUILDENV) ./autogen.sh $(CONFIGURE_OPTS) --prefix= ; \
		make all; \
		perl -pi -e "s,^prefix=.*$$,prefix=$(TARGETPREFIX)," vorbisidec.pc; \
		make install DESTDIR=$(TARGETPREFIX); \
		make install DESTDIR=$(PKGPREFIX); \
		install -m644 vorbisidec.pc $(TARGETPREFIX)/lib/pkgconfig
	$(REWRITE_LIBTOOL)/libvorbisidec.la
	rm -r $(PKGPREFIX)/lib/pkgconfig $(PKGPREFIX)/include
	rm $(PKGPREFIX)/lib/*a
	PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		PKG_VER=$(VORBISIDEC_SVN) $(OPKG_SH) $(CONTROL_DIR)/libvorbisidec
	$(REMOVE)/libvorbisidec-$(VORBISIDEC_VER) $(PKGPREFIX)
	touch $@

FUSE_DRIVER="fuse.ko"
FUSE_NEEDS_KO = true
ifeq ($(PLATFORM), spark)
FUSE_NEEDS_KO = false
endif
ifeq ($(PLATFORM), azbox)
FUSE_NEEDS_KO = false
endif
ifeq ($(PLATFORM), coolstream)
FUSE_DRIVER="cs-drivers"
endif
FUSE_PROVIDES="libfuse.so.2, libfuse.so.2, libulockmgr.so.1, mount.fuse, fusermount, ulockmgr_server"
$(D)/fuse: $(ARCHIVE)/fuse-$(FUSE_VER).tar.gz | $(TARGETPREFIX)
	rm -rf $(PKGPREFIX)
	$(UNTAR)/fuse-$(FUSE_VER).tar.gz
	set -e; cd $(BUILD_TMP)/fuse-$(FUSE_VER); \
		$(CONFIGURE) --prefix= --mandir=/.remove; \
		$(MAKE) all; \
		make install DESTDIR=$(TARGETPREFIX) ;\
		make install DESTDIR=$(PKGPREFIX)
	$(REWRITE_LIBTOOL)/libfuse.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/fuse.pc
	set -e; cd $(PKGPREFIX); \
		rm -rf dev etc lib/pkgconfig include .remove; \
		rm lib/*.so lib/*.la lib/*.a
ifeq ($(FUSE_NEEDS_KO), true)
	install -m 755 -D $(SCRIPTS)/load-fuse.init \
		$(PKGPREFIX)/etc/init.d/load-fuse
	ln -s load-fuse $(PKGPREFIX)/etc/init.d/S56load-fuse
	PKG_DEP=$(FUSE_DRIVER) PKG_VER=$(FUSE_VER) \
	PKG_PROV=$(FUSE_PROVIDES) \
		$(OPKG_SH) $(CONTROL_DIR)/fuse
else
	PKG_DEP=" " PKG_VER=$(FUSE_VER) \
	PKG_PROV=$(FUSE_PROVIDES) \
		$(OPKG_SH) $(CONTROL_DIR)/fuse
endif
	$(REMOVE)/fuse-$(FUSE_VER) $(PKGPREFIX)
	touch $@

# build only static lib - just needed by tcpdump
$(D)/libpcap: $(ARCHIVE)/libpcap-$(LIBPCAP_VER).tar.gz
	rm -rf $(PKGPREFIX)
	$(UNTAR)/libpcap-$(LIBPCAP_VER).tar.gz
	set -e; cd $(BUILD_TMP)/libpcap-$(LIBPCAP_VER); \
		echo "ac_cv_linux_vers=2" >> config.cache; \
		$(CONFIGURE) --with-pcap=linux --prefix= --mandir=/.remove -C; \
		$(MAKE) all ; \
		make install DESTDIR=$(TARGETPREFIX); \
		: make install DESTDIR=$(PKGPREFIX)
	rm -rf $(TARGETPREFIX)/.remove $(PKGPREFIX)/.remove \
		$(PKGPREFIX)/bin $(PKGPREFIX)/include $(PKGPREFIX)/lib/*.a
	rm -rf $(TARGETPREFIX)/lib/libpcap.s*
	$(REMOVE)/libpcap-$(LIBPCAP_VER)
	touch $@

# timezone definitions. Package only those referenced by timezone.xml
# zic is usually in a package called "timezone" or similar.
$(D)/timezone: find-zic $(ARCHIVE)/tzdata$(TZ_VER).tar.gz
	$(REMOVE)/timezone $(PKGPREFIX)
	mkdir $(BUILD_TMP)/timezone $(BUILD_TMP)/timezone/zoneinfo
	tar -C $(BUILD_TMP)/timezone -xf $(ARCHIVE)/tzdata$(TZ_VER).tar.gz
	set -e; cd $(BUILD_TMP)/timezone; \
		unset ${!LC_*}; LANG=POSIX; LC_ALL=POSIX; export LANG LC_ALL; \
		zic -d zoneinfo.tmp \
			africa antarctica asia australasia \
			europe northamerica southamerica pacificnew \
			etcetera backward; \
		sed -n '/zone=/{s/.*zone="\(.*\)".*$$/\1/; p}' $(PATCHES)/timezone.xml | sort -u | \
		while read x; do \
			find zoneinfo.tmp -type f -name $$x | sort | \
			while read y; do \
				cp -a $$y zoneinfo/$$x; \
			done; \
			test -e zoneinfo/$$x || echo "WARNING: timezone $$x not found."; \
		done; \
		install -d -m 0755 $(PKGPREFIX)/share/ $(PKGPREFIX)/usr/share $(PKGPREFIX)/etc; \
		mv zoneinfo $(PKGPREFIX)/share/
	ln -s ../../share/zoneinfo $(PKGPREFIX)/usr/share/
	install -m 0644 $(PATCHES)/timezone.xml $(PKGPREFIX)/etc/
	PKG_VER=$(TZ_VER) $(OPKG_SH) $(CONTROL_DIR)/timezone
	$(REMOVE)/timezone $(PKGPREFIX)
	touch $@

#############################################################################################
#############################################################################################
######### not yet needed and not tested #####################################################
#############################################################################################
#############################################################################################

# builds only static lib, needed e.g. by unfsd
$(D)/libflex: $(ARCHIVE)/flex-$(FLEX_VER).tar.gz
	$(UNTAR)/flex-$(FLEX_VER).tar.gz
	set -e; cd $(BUILD_TMP)/flex-$(FLEX_VER); \
		echo "ac_cv_func_malloc_0_nonnull=yes" > config.cache; \
		echo "ac_cv_func_realloc_0_nonnull=yes" >> config.cache; \
		$(CONFIGURE) -C --host=$(TARGET) --target=$(TARGET) --prefix= --bindir=/.remove --mandir=/.remove --infodir=/.remove --disable-nls; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	rm -fr $(TARGETPREFIX)/.remove
	$(REMOVE)/flex-$(FLEX_VER)
	touch $@

$(D)/libexpat: $(ARCHIVE)/expat-$(EXPAT_VER).tar.gz
	$(UNTAR)/expat-$(EXPAT_VER).tar.gz
	set -e; cd $(BUILD_TMP)/expat-$(EXPAT_VER); \
		$(CONFIGURE) -C --host=$(TARGET) --target=$(TARGET) --prefix= --bindir=/.remove --mandir=/.remove --infodir=/.remove --disable-nls; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	rm -fr $(TARGETPREFIX)/.remove
	$(REWRITE_LIBTOOL)/libexpat.la
	$(REMOVE)/expat-$(EXPAT_VER)
	touch $@

# !!! libcap != libpcap !!!
# only the libs will be installed!
$(D)/libcap: $(ARCHIVE)/libcap2_$(LIBCAP2_VER).orig.tar.gz $(D)/libattr1
	$(UNTAR)/libcap2_$(LIBCAP2_VER).orig.tar.gz
	set -e; cd $(BUILD_TMP)/libcap-$(LIBCAP2_VER); \
		export CROSS_BASE=$(CROSS_BASE); export TARGET=$(TARGET); export TARGETPREFIX=$(TARGETPREFIX);\
		patch -p1 < $(PATCHES)/libcap-$(LIBCAP2_VER).patch;\
		$(MAKE);\
		$(MAKE) -C libcap INCDIR=$(TARGETPREFIX)/include LIBDIR=$(TARGETPREFIX)/lib  install
	$(REMOVE)/libcap2_$(LIBCAP2_VER)
	touch $@

$(D)/libattr1: $(ARCHIVE)/attr-$(ATTR_VER).src.tar.gz
	$(UNTAR)/attr-$(ATTR_VER).src.tar.gz
	set -e; cd $(BUILD_TMP)/attr-$(ATTR_VER); \
		$(CONFIGURE) \
			--prefix= \
			--enable-gettext=no \
			--mandir=/.remove \
			--datadir=/.remove; \
		$(MAKE); \
		make install-lib install-dev DIST_ROOT=$(TARGETPREFIX)
	$(REMOVE)/attr-$(ATTR_VER) $(TARGETPREFIX)/.remove
	rm $(TARGETPREFIX)/lib/libattr.*a $(TARGETPREFIX)/libexec/libattr.so
	mv $(TARGETPREFIX)/libexec/libattr* $(TARGETPREFIX)/lib/
	$(REWRITE_LIBTOOL)/libattr.la
	touch $@

$(D)/libdvbsi++: $(ARCHIVE)/libdvbsi++-$(LIBDVBSI_VER).tar.bz2 \
$(PATCHES)/libdvbsi++-src-time_date_section.cpp-fix-sectionLength-check.patch \
$(PATCHES)/libdvbsi++-fix-unaligned-access-on-SuperH.patch
	$(REMOVE)/libdvbsi++-$(LIBDVBSI_VER)
	$(UNTAR)/libdvbsi++-$(LIBDVBSI_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/libdvbsi++-$(LIBDVBSI_VER); \
			$(PATCH)/libdvbsi++-src-time_date_section.cpp-fix-sectionLength-check.patch; \
			$(PATCH)/libdvbsi++-fix-unaligned-access-on-SuperH.patch; \
			$(CONFIGURE) \
				--prefix=$(TARGETPREFIX) \
				--build=$(BUILD) \
				--host=$(TARGET); \
			$(MAKE); \
			$(MAKE) install
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(BUILD_TMP)/libdvbsi++-$(LIBDVBSI_VER)/src/.libs/libdvbsi++.so.* $(PKGPREFIX)/lib
	PKG_DEP=" " PKG_VER=$(LIBDVBSI_VER) PKG_VER=$(LIBDVBSI_VER) \
	PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
	$(OPKG_SH) $(CONTROL_DIR)/libdvbsi++
	$(REMOVE)/libdvbsi++-$(LIBDVBSI_VER) $(PKGPREFIX)
	touch $@

# no package, since the library is only built statically
$(D)/lua: libncurses $(ARCHIVE)/lua-$(LUA_VER).tar.gz \
	$(ARCHIVE)/luaposix-$(LUAPOSIX_VER).tar.bz2 $(PATCHES)/lua-5.2.1-luaposix.patch
	$(REMOVE)/lua-$(LUA_VER)
	$(UNTAR)/lua-$(LUA_VER).tar.gz
	set -e; cd $(BUILD_TMP)/lua-$(LUA_VER); \
		$(PATCH)/lua-$(LUA_VER)-luaposix-$(LUAPOSIX_VER).patch; \
		tar xf $(ARCHIVE)/luaposix-$(LUAPOSIX_VER).tar.bz2; \
		cd luaposix-$(LUAPOSIX_VER)/ext; cp posix/posix.c include/lua52compat.h ../../src/; cd ../..; \
		sed -i 's/<config.h>/"config.h"/' src/posix.c; \
		sed -i '/^#define/d' src/lua52compat.h; \
		sed -i 's@^#define LUA_ROOT.*@#define LUA_ROOT "/"@' src/luaconf.h; \
		sed -i '/^#define LUA_USE_READLINE/d' src/luaconf.h; \
		sed -i 's/ -lreadline//' src/Makefile; \
		sed -i 's|man/man1|.remove|' Makefile; \
		$(MAKE) linux CC=$(TARGET)-gcc LDFLAGS="-L$(TARGETPREFIX)/lib" ; \
		$(MAKE) install INSTALL_TOP=$(TARGETPREFIX)
	rm -rf $(TARGETPREFIX)/.remove
	$(REMOVE)/lua-$(LUA_VER)
	touch $@


$(D)/mrua: $(ARCHIVE)/azboxme-mrua-3.11-1.tar.gz openssl libungif
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	tar -C $(PKGPREFIX)/lib -xf $(ARCHIVE)/azboxme-mrua-3.11-1.tar.gz
	export PKG_DEP_=`opkg-find-requires.sh $(PKGPREFIX)`; \
		export PKG_PROV=`cd $(PKGPREFIX)/lib; echo *|sort|sed "s/ /, /g"`; \
		set -x; \
		PKG_DEP=""; \
		for i in $$PKG_DEP_; do \
			FOUND=false; \
			for j in $$PKG_PROV; do \
				if test $$j = $$i; then \
					FOUND=true; \
					break; \
				fi; \
			done; \
			$$FOUND || PKG_DEP="$$PKG_DEP $$i"; \
		done; \
		export PKG_DEP; \
		PKG_VER=3.11.1 \
		$(OPKG_SH) $(CONTROL_DIR)/mrua-libs
	rm -rf $(PKGPREFIX)
	touch $@

$(TARGETPREFIX)/bin/rmfp_player: mrua | $(TARGETPREFIX)/bin
	wget -O $@ 'http://azboxopenpli.git.sourceforge.net/git/gitweb.cgi?p=azboxopenpli/openembedded;a=blob;f=recipes/azbox/azbox-azplayer/bin/rmfp_player'
	chmod 755 $@

rmfp_player: mrua
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/bin
	wget -O $(PKGPREFIX)/bin/rmfp_player 'http://azboxopenpli.git.sourceforge.net/git/gitweb.cgi?p=azboxopenpli/openembedded;a=blob;f=recipes/azbox/azbox-azplayer/bin/rmfp_player'; \
	set -e; V=`$(BASE_DIR)/scripts/get-sf-git-binary-timestamp.pl \
			azboxopenpli/openembedded recipes/azbox/azbox-azplayer/bin/rmfp_player`; \
		PKG_VER=$$V PKG_AUTOREQPROV=1 $(OPKG_SH) $(CONTROL_DIR)/rmfp_player; \
	rm -rf $(PKGPREFIX)

#libsigc++: typesafe Callback Framework for C++
$(D)/libsigc++: $(ARCHIVE)/libsigc++-$(LIBSIGCPP_VER).tar.xz | $(TARGETPREFIX)
	rm -rf $(PKGPREFIX)
	$(UNTAR)/libsigc++-$(LIBSIGCPP_VER).tar.xz
	set -e; cd $(BUILD_TMP)/libsigc++-$(LIBSIGCPP_VER); \
		$(CONFIGURE) -prefix= \
				--disable-documentation \
				--enable-silent-rules; \
		$(MAKE); \
		make install DESTDIR=$(TARGETPREFIX); \
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/lib/libsigc-2.0.so* $(PKGPREFIX)/lib
	ln -sf ./sigc++-2.0/sigc++ $(TARGETPREFIX)/include/sigc++
	cp $(BUILD_TMP)/libsigc++-$(LIBSIGCPP_VER)/sigc++config.h $(TARGETPREFIX)/include
	$(REWRITE_LIBTOOL)/libsigc-2.0.la
	PKG_VER=$(LIBSIGCPP_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
			$(OPKG_SH) $(CONTROL_DIR)/libsigc++
	$(REMOVE)/libsigc++-$(LIBSIGCPP_VER)
	rm -rf $(PKGPREFIX)
	touch $@

PHONY += ncurses-prereq rmfp_player
