#master makefile

SHELL = /bin/bash
UID := $(shell id -u)
ifeq ($(UID), 0)
warn:
	@echo "You are running as root. Don't do this, it's dangerous."
	@echo "Refusing to build. Good bye."
else

include make/environment.mk

############################################################################
#  A print out of environment variables
#
# maybe a help about all supported targets would be nice here, too...
#
printenv:
	@echo '============================================================================== '
	@echo "Build Environment Varibles:"
	@echo "CROSS_DIR:   $(CROSS_DIR)"
	@echo "CROSS_BASE:  $(CROSS_BASE)"
	@echo "TARGET:      $(TARGET)"
	@echo "BASE_DIR:    $(BASE_DIR)"
	@echo "BUILD:       $(BUILD)"
	@echo "PATH:        `type -p fmt>/dev/null&&echo $(PATH)|sed 's/:/ /g' |fmt -65|sed 's/ /:/g; 2,$$s/^/             /;'||echo $(PATH)`"
	@echo "N_HD_SOURCE: $(N_HD_SOURCE)"
	@echo "BOXARCH:     $(BOXARCH)"
	@echo "PLATFORM:    $(PLATFORM)"
	@echo "KVERSION:    $(KVERSION)"
	@echo "MAINTAINER:  $(MAINTAINER)"
	@echo '============================================================================== '
	@echo "LOCAL_NEUTRINO_BUILD_OPTIONS:  $(LOCAL_NEUTRINO_BUILD_OPTIONS)"
	@echo "LOCAL_NEUTRINO_CFLAGS:  $(LOCAL_NEUTRINO_CFLAGS)"
	@echo ""
	@echo "'make help' lists useful targets."
	@echo "The doc/ directory contains documentation. Read it."
	@echo ""
	@make --no-print-directory toolcheck
ifeq ($(MAINTAINER),)
	@echo "##########################################################################"
	@echo "# The MAINTAINER variable is not set. It defaults to your name from the  #"
	@echo "# passwd entry, but this seems to have failed. Please set it in 'config'.#"
	@echo "##########################################################################"
	@echo
endif
	@LC_ALL=C make -n preqs|grep -q "Nothing to be done" && P=false || P=true; \
	test -d $(TARGETPREFIX) && T=false || T=true; \
	type -p $(TARGET)-pkg-config >/dev/null 2>&1 || T=true; \
	PATH=$(PATH):$(CROSS_DIR)/bin; \
	type -p $(TARGET)-gcc >/dev/null 2>&1 && C=false || C=true; \
	if $$P || $$T || $$C; then \
		echo "Your next steps are most likely (in this order):"; \
		$$P && echo "	* 'make preqs'		for prerequisites"; \
		$$C && echo "	* 'make crosstool'	for the cross compiler"; \
		$$T && echo "	* 'make bootstrap'	to prepare the target root"; \
		echo; \
	fi

ifeq ($(PLATFORM), tripledragon)
	@PATH=$(K_GCC_PATH):$(PATH); if type -p powerpc-405-linux-gnu-gcc >/dev/null 2>&1; then \
		echo "kernelgcc (powerpc-405-linux-gnu-gcc) found."; \
	else \
		echo "##############################################################################"; \
		echo "Could not find the gcc 3.x for building kernel modules. You will probably need"; \
		echo "it later to build the necessary kernel modules. Please do 'make kernelgcc' now"; \
		echo "(you can also do this later if necessary)."; \
		echo "##############################################################################"; \
	fi
endif
	@if ! test -e $(BASE_DIR)/config; then \
		echo;echo "If you want to change the configuration, copy 'doc/config.example' to 'config'"; \
		echo "and edit it to fit your needs. See the comments in there."; echo; fi

help:
	@echo "a few helpful make targets:"
	@echo "* make preqs               - downloads necessary stuff"
	@echo "* make crosstool           - build cross toolchain"
	@echo "* make bootstrap           - prepares for building"
	@echo "* make neutrino            - builds neutrino"
	@echo "* make minimal-system-pkgs - build enough to have a bootable system, consult"
	@echo "                             doc/README.opkg-bootstrap how to continue from there"
	@echo "* make devel-tools         - build gdb and strace for the target"
	@echo "* make print-targets       - print out all available targets"
	@echo ""
	@echo "later, you might find those useful:"
	@echo "* make update-self         - update the build system"
	@echo "* make update-neutrino     - update the neutrino source"
ifeq ($(PLATFORM), coolstream)
	@echo "* make update-svn          - update the coolstream svn parts (mainly drivers)"
	@echo "* make update-svn-target   - copy updated svn parts into \$$TARGETPREFIX"
endif
	@echo ""
	@echo "cleantargets:"
	@echo "make clean                 - clean neutrino build dir"
	@echo "make rebuild-clean         - additionally remove \$$TARGETPREFIX, but keep the toolchain"
	@echo "                             after that you need to restart with 'bootstrap'"
	@echo "make all-clean             - additionally remove the crosscompiler"
	@echo "                             you usually don't want to do that."
	@echo

ifeq ($(BOXARCH), sh4)
include make/stlinux.mk
endif
# define package versions first...
include make/versions.mk

include make/prerequisites.mk
include make/bootstrap.mk
include make/system-libs.mk
include make/system-tools.mk
include make/devel-tools.mk
#include make/tuxbox.mk
include make/neutrino.mk
include make/cleantargets.mk
include make/linuxkernel.mk
include make/archives.mk
include make/extras.mk
include make/gstreamer.mk
include make/packages.mk
include make/plugins.mk
include make/example.mk
include make/flashimage.mk
include make/crosstool-$(BOXARCH).mk

update-self:
	git pull

ifneq ($(PLATFORM), tripledragon)
# only updates important(?) stuff, no crosstool etc.
# not useful on tripledragon, because that SVN never changes
update-svn: | $(SOURCE_DIR)/svn/THIRDPARTY/lib
	for i in $(SOURCE_DIR)/svn/COOLSTREAM \
		$(SOURCE_DIR)/svn/CROSSENVIROMENT/coolstream; \
	do \
		if [ -d $$i ]; then \
			echo "updating $$i..."; \
			(cd $$i && $(SVN) up); \
		else true; fi \
	done
	for i in $(SOURCE_DIR)/svn/THIRDPARTY/*; \
	do \
		if [ -d $$i ]; then \
			echo "updating $$i..."; \
			(cd $$i && $(SVN) up *); \
		else true; fi \
	done

update-svn-target:
	make cs-modules includes-and-libs
else
update-svn:
	@echo "update-svn is not useful on $(PLATFORM)"
endif

ifneq ("$(FLAVOUR)", "neutrino-hd")
NOW := $(shell date +%Y%m%d-%H%M%S)
N_HD_SOURCE_S = $(subst $(BASE_DIR)/,"",$(N_HD_SOURCE))

update-neutrino:
	@if test -d $(SOURCE_DIR)/libstb-hal; then \
		cd $(SOURCE_DIR)/libstb-hal; echo "=== updating libstb-hal ==="; git pull; fi
	@if test -d $(SOURCE_DIR)/tdt-driver; then \
		cd $(SOURCE_DIR)/tdt-driver; echo "=== updating tdt-driver ==="; git pull; fi
	@if test -d $(SOURCE_DIR)/tdt; then \
		cd $(SOURCE_DIR)/tdt; git branch "before-update-$(NOW)"; \
		echo "=== updating tdt git ==="; git pull; fi
	@cd $(N_HD_SOURCE) && { \
		echo "=== updating neutrino git ==="; \
		git branch "before-update-$(NOW)"; git stash save "before update $(NOW)"; \
		git pull || { \
			echo ""; \
			echo "An error occured during git pull. This is probably due to a";	\
			echo "rebased upstream tree. In this case, the easiest way to recover";	\
			echo "is probably to do 'make update-neutrino-hard', which will do a";	\
			echo "'git reset --hard origin/master' in $(N_HD_SOURCE_S).";		\
			echo ""; \
			echo "The state before update was saved in branch 'before-update-$(NOW)'"; \
			}; \
		}
	@echo ""
	@echo "Sources updated. Local changes before update were stashed away,"
	@echo "try 'git stash list' in $(N_HD_SOURCE_S) and restore with"
	@echo "'git stash pop' there."

update-neutrino-hard:
	cd $(N_HD_SOURCE) && git reset --hard origin/master

else
update-neutrino:
	cd $(N_HD_SOURCE) && git pull
endif

update-uncool:
	set -e; cd $(UNCOOL_GIT); \
		for i in cst-*; do \
			( echo updating $$i; cd $$i; git pull; ); \
		done
	if test -d $(UNCOOL_GIT)/cst-public-libraries-ffmpeg; then \
		cd $(UNCOOL_GIT)/cst-public-libraries-ffmpeg; \
		if [ x"`git rev-parse --abbrev-ref HEAD`" != xmaster ]; then \
			X=`git branch --list master`; \
			if [ x`echo $$X` = xmaster ]; then \
				git checkout master; \
			else \
				git checkout -b master origin/master; \
			fi; \
		fi; \
	fi


all:
	@echo "'make all' is not a valid target. Please read the documentation."

# target for testing only. not useful otherwise
everything: $(shell sed -n 's/^\$$.D.\/\(.*\):.*/\1/p' make/*.mk)

# print all present targets...
print-targets:
	sed -n 's/^\$$.D.\/\(.*\):.*/\1/p; s/^\([a-z].*\):\( \|$$\).*/\1/p;' \
		`ls -1 make/*.mk|grep -v make/unmaintained.mk` Makefile | \
		sort -u | fold -s -w 65


$(BUILD_TMP)/Makefile.archivecheck: | $(BUILD_TMP)
	rm -f $@
	BOXARCH=$(BOXARCH) scripts/archivecheck.pl > $@

archivecheck: $(BUILD_TMP)/Makefile.archivecheck
	make -f $(BUILD_TMP)/Makefile.archivecheck

# for local extensions, e.g. special plugins or similar...
# put them into $(BASE_DIR)/local since that is ignored in .gitignore
-include ./Makefile.local

# debug target, if you need that, you know it. If you don't know if you need
# that, you don't need it.
.print-phony:
	@echo $(PHONY)

PHONY += $(BUILD_TMP)/Makefile.archivecheck
PHONY += everything print-targets
PHONY += all printenv .print-phony
PHONY += update-svn update-svn-target update-neutrino update-self
.PHONY: $(PHONY)

# this makes sure we do not build top-level dependencies in parallel
# (which would not be too helpful anyway, running many configure and
# downloads in parallel...), but the sub-targets are still built in
# parallel, which is useful on multi-processor / multi-core machines
.NOTPARALLEL:
endif
