# Makefile to define the versions of the packages
# define the version of a package here, so you don't have to write
# it everyvere in different makefiles and its targets

# !!! If you change a version of an package, please check if a patchfile
# !!! is also to addapt. Even if a patch is named with the version 
# !!! inside the string it is expandable with the version variable.

###########################
# Libs; make/system-libs.mk
###########################

# azbox-dvb-modules
# not the most useful date format...
AZBOX_DVB_M_VER=14092013
# not the most useful date format...
AZBOX_INITRAMFS_ME=14092013
AZBOX_INITRAMFS_MINIME=14092013

# libdid3tag; writing, reading and manipulating ID3 tags
ID3TAG_VER=0.15.1
ID3TAG_SUBVER=b

# libmad; MPEG audio decoder
MAD_VER=0.15.1b

# libungif; converting images
UNGIF_VER=4.1.4

# giflib: replaces libungif
GIFLIB_VER=5.0.4

# libiconv; converting encodings
ICONV-VER=1.14

# iperf: network performance measurement
IPERF-VER=2.0.5

# zlib; compression an decompressin library
ZLIB_VER=1.2.7

# util-linux-ng; tools for filesystems, partitions, console und system messages
UTIL_LINUX_NG_VER=2.18

# curl; command line tool for transferring data with URL syntax
CURL_VER=7.28.0

# libpng; reference library for reading and writing PNGs
PNG_VER=1.6.6

# freetype; free, high-quality and portable Font engine
FREETYPE_VER=2.5.0.1

# libjpeg-turbo; a derivative of libjpeg for x86 and x86-64 processors which uses SIMD instructions (MMX, SSE2, etc.) to accelerate baseline JPEG compression and decompression
JPEG_TURBO_VER=1.2.1

# boost; portable C++ source library
BOOST_MAJOR=1
BOOST_MINOR=52
BOOST_MICRO=0
BOOST_VER=$(BOOST_MAJOR)_$(BOOST_MINOR)_$(BOOST_MICRO)

# openssl; toolkit for the SSL v2/v3 and TLS v1 protocol
OPENSSL_VER=0.9.8
OPENSSL_SUBVER=q

# libffmpeg; complete, cross-platform solution to record, convert and stream audio and video
FFMPEG_VER=2.1.3
ifeq ($(PLATFORM), coolstream)
FFMPEG_VER=1.2
endif

# libogg; encoding, decoding of the ogg file format
OGG_VER=1.3.0

# libvorbis; encoding, decoding fixed or variable bitrates of ogg vorbis formats
VORBIS_VER=1.3.3

# libass: ass / ssa subtitle renderer
LIBASS_VER=0.9.11

# azbox kernel
LINUX_AZBOX_VER=3.9.2

# LIRC: linux infrared control
LIRC_VER=0.9.0

# lua: easily embeddable scripting language
LUA_VER=5.2.3

# luaposix: posix bindings for lua
LUAPOSIX_VER=31

# ncurses; software for controlling writing to the console screen
NCURSES_VER=5.6

# nano; a simple editor for Linux
NANO_VER=2.2.6

# DirectFB; thin library that provides hardware graphics acceleration, input device handling and abstraction
DIRECTFB_VER=1.4.3

# libdvdcss: a simple library designed for accessing DVDs like a block device
# without having to bother about the decryption.
DVDCSS_VER=1.2.12

# libvorbisidec;  libvorbisidec is an Ogg Vorbis audio decoder (also known as "tremor") with no floating point arithmatic
VORBISIDEC_SVN=18153
VORBISIDEC_VER=1.0.2+svn$(VORBISIDEC_SVN)
VORBISIDEC_VER_APPEND=.orig

# libpcap; system-independent interface for user-level packet capture
LIBPCAP_VER=1.2.0

# libcap; setting and proofing POSIX.1e functionality (Version 2!)
LIBCAP2_VER=2.22

# flex; fast lexical analyser generator
FLEX_VER=2.5.35

# libexpat; XML parser
EXPAT_VER=2.0.1

# attr; setting up extended attributes
ATTR_VER=2.4.44

# libdvbsi++; libdvbsi++ is a open source C++ library for parsing DVB Service Information and MPEG-2 Program Specific Information.
LIBDVBSI_VER=0.3.6

#############################
# tools; make/system-tools.mk
#############################

# vsftpd; a small, tiny and "v"ery "s"ecure "ftp" deamon
VSFTPD_VER=2.3.5

# rsync; fast and extraordinarily versatile file copying tool
RSYNC-VER=3.0.7

# pkg-config; a helper tool used when compiling applications and libraries to insert the correct compiler options
PKGCONFIG_VER=0.26

# procps; a bunch of small useful utilities that give information about processes using the /proc filesystem
PROCPS-VER=3.2.8

# busybox; combines tiny versions of many common UNIX utilities into a single binary
BUSYBOX_REL = 1.21
BUSYBOX_PATCH = 1
BUSYBOX_VER = $(BUSYBOX_REL).$(BUSYBOX_PATCH)

# e2fsprogs; filesystem utilities for use with the ext[x] filesystem
E2FSPROGS-VER=1.42

# xfsprogs; Utilities for managing the XFS filesystem
XFSPROGS-VER=3.1.8

# ntfs-3g; file system driver for the NTFS file system, enabling read/write support of NTFS file systems
NTFS_3G_VER=2012.1.15

# autofs; mounting filesystems on demand
AUTOFS-VER=4.1.4

# samba; standard Windows interoperability suite of programs for Linux and Unix
SAMBA2-VER=2.2.12
SAMBA3-VER=

STRACE_VER=4.7

# portmap; an ONC RPC service that runs on network nodes that provide other ONC RPC services
PORTMAP-VER=6.0

# unfs3; a user-space implementation of the NFSv3 server specification
UNFS3-VER=0.9.22

# fbshot;  a small program that allowes you to take screenshots from the framebuffer
FBSHOT-VER=0.3

# tcpdump. if you don't know it, you don't need it.
TCPDUMP-VER=4.2.0

# timezone files
TZ_VER = 2012b

# systemd; a system and service manager for Linux
SYSTEMD-VER=19

# dbus; message bus system
DBUS-VER=1.4.6

# ntp; synchronize system clock over a network
NTP_VER=4.2.6p5

# valgrind debugging and profiling tool suite
VALGRIND_VER = 3.8.1

#########################
# extras; make/extras.mk
########################

GSTREAMER_VER=0.10.36
GST_PLUG_GOOD_VER=0.10.31
GST_PLUG_BAD_VER=0.10.23
GST_FFMPEG_VER=0.10.13
GST123_VER=0.3.1

LIBFFI_VER=3.0.11

# links; a text WWW browser, similar to Lynx
LINKS-VER=2.3pre1

# qt-everythere-opensource-src; the Qt4 package contains several C++ libraries with both GUI and non-GUI components
QT-VER=4.6.3

# nbench; a benchmark program that will measure the performance
NBENCH_BYTE-VER=2.2.3

# libupnp; a portable open source UPnP development kit
LIBUPNP_VER=1.6.17

LIBXML2_VER=2.8.0

# dropbear; a relatively small SSH 2 server and client
DROPBEAR-VER=0.53.1

# opkg; a lightweight package management system based on Ipkg
OPKG_VER=0.2.0

## for recent versions, the SVN trunk rev is used:
#OPKG_SVN=635
#OPKG_SVN_VER=$(OPKG-VER)+svnr$(OPKG_SVN)

# glib; the low-level core library that forms the basis for projects such as GTK+ and GNOME
GLIB_MAJOR=2
GLIB_MINOR=36
GLIB_MICRO=4
GLIB_VER=$(GLIB_MAJOR).$(GLIB_MINOR).$(GLIB_MICRO)

# mc; the famous midnight commander
MC-VER=4.6.2

# sg3_utils; a package of utilities for accessing devices that use SCSI command sets
SG3_UTILS-VER=1.33

# FUSE; filesystems in userspace
FUSE_VER=2.9.2

# ALSA, the Advanced Linux Sound Architecture
ALSA_VER=1.0.25

# libusb; a C library that gives applications easy access to USB devices
USB_VER=1.0.9

#libusb-compat; a replacement/wrapper for libusb-0.1
USBCMPT_VER=0.1.4

#dpf-ax; an attempt to create a replacement firmware for AX206 based digital picture frames
DPF-AXREV=40

# LCD4Linux; a small program that grabs information from the kernel and some subsystems and displays it on an external liquid crystal display
LCD4LINUX_VER=0.10.0
LCD4LINUX_SVN=1184
LCD4LINUX_SVN_VER=$(LCD4LINUX_VER)+svnr$(LCD4LINUX_SVN)

##################################
# devel-tools; make/devel-tools.mk
##################################

# gdb; the GNU debugger
GDB_VER=7.3

# mtd-utils for the host...
MTD_UTILS_VER = 1.4.9

# wget for retrieving files using HTTP, HTTPS and FTP
WGET_VER=1.14

#xmlto, shell-script tool for converting XML files to various formats.
XMLTO_VER=0.0.25

#libsigc++: typesafe Callback Framework for C++
LIBSIGCPP_MAJOR=2
LIBSIGCPP_MINOR=3
LIBSIGCPP_MICRO=1
LIBSIGCPP_VER=$(LIBSIGCPP_MAJOR).$(LIBSIGCPP_MINOR).$(LIBSIGCPP_MICRO)

#djmount: mount MediaServers content as a Linux filesystem 
DJMOUNT_VER=0.71

LIBBLURAY_VER = 0.5.0
