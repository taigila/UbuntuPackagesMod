# -*- Mode: makefile-gmake; tab-width: 4; indent-tabs-mode: t -*-
#
# This file is part of the LibreOffice project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

gb_Top_MODULE_CHECK_TARGETS := slowcheck unitcheck subsequentcheck perfcheck uicheck screenshot

.PHONY : all check-if-root bootstrap gbuild build build-non-l10n-only build-l10n-only check clean clean-build clean-host test-install distclean distro-pack-install docs download etags fetch get-submodules id install install-gdb-printers install-strip tags debugrun help showmodules translations packageinfo internal.clean $(gb_Top_MODULE_CHECK_TARGETS)

MAKECMDGOALS?=all
build_goal:=$(if $(filter build check,$(MAKECMDGOALS)),all)\
 $(if $(filter build-nocheck slowcheck uicheck,$(MAKECMDGOALS)),build)\
 $(if $(filter check,$(MAKECMDGOALS)),subsequentcheck $(if $(filter Linux, $(shell uname)), uicheck))\
 $(filter all build-l10n-only build-non-l10n-only debugrun help showmodules translations $(gb_Top_MODULE_CHECK_TARGETS) check packageinfo gbuildtojson,$(MAKECMDGOALS))

SRCDIR := /home/ubuntu2004/Documents/LibreOffice/libreoffice-6.4.7
BUILDDIR := /home/ubuntu2004/Documents/LibreOffice/libreoffice-6.4.7
COMPILER_PLUGINS := 
GIT_BUILD := $(if $(wildcard $(SRCDIR)/.git),T)

# Run autogen.sh if needed and force make to restart itself.
# ... but there are several cases where we do not want to run
# autogen.sh:
# 1. if we are building from tarballs, not git checkout (I do not
#    think packagers would ever want that. I certainly do not.)
# 2. if we are making help, clean or distclean, because they do not
#    need updated configuration
ifeq (,$(MAKE_RESTARTS)$(if $(GIT_BUILD),,T)$(if $(filter-out help showmodules clean distclean,$(MAKECMDGOALS)),,T))

# note: this must touch both Makefile and $(BUILDDIR)/Makefile, because make
# may be invoked using either of these paths, and it will restart itself only
# if the updated target is exactly the same path as the Makefile it is using
.PHONY : force-restart
Makefile $(BUILDDIR)/Makefile: $(BUILDDIR)/config_host.mk $(BUILDDIR)/config_host_lang.mk force-restart
	@touch $@

# run configure in an environment not polluted by config_host.mk
$(BUILDDIR)/config_host.mk : $(wildcard \
		$(SRCDIR)/config_host.mk.in \
		$(SRCDIR)/config_host_lang.mk.in \
		$(SRCDIR)/Makefile.in \
		$(SRCDIR)/instsetoo_native/util/openoffice.lst.in \
		$(SRCDIR)/configure.ac \
		$(SRCDIR)/config_host/*.h.in \
		$(SRCDIR)/download.lst \
		$(BUILDDIR)/autogen.input \
		$(BUILDDIR)/autogen.lastrun \
		$(BUILDDIR)/autogen.sh \
		) \
		$(shell . $(SRCDIR)/bin/get_config_variables JAVA_HOME && \
			if test -n "$${JAVA_HOME}" -a ! -d "$${JAVA_HOME}/bin"; then echo force-restart; fi)
	sh -c $(SRCDIR)/autogen.sh

else # MAKE_RESTARTS

all: paul build

gb_Side ?= host

include $(BUILDDIR)/config_$(gb_Side).mk

export GMAKE_OPTIONS?=-r$(if $(verbose),,s)$(value $(MAKEFLAGS))

PARALLELISM_OPTION := $(if $(filter-out 0,$(PARALLELISM)),-j $(PARALLELISM),)

IWYU_OPTION := $(if $(IWYU_PATH),-k CC=$(IWYU_PATH) CXX=$(IWYU_PATH),)

# don't want to have a dependency to iwyudummy.generate because it's
# useful to manually edit the generated StaticLibrary_iwyudummy.mk
iwyudummy: bootstrap fetch
	$(if $(wildcard $(BUILDDIR)/iwyudummy),,$(error first call "make iwyudummy.generate"))
	cd $(BUILDDIR)/iwyudummy && $(MAKE) $(IWYU_OPTION) $(GMAKE_OPTIONS)

iwyudummy.generate:
	$(SRCDIR)/bin/gen-iwyu-dummy-lib

#
# Partial Build
#
define gb_Top_GbuildModuleRules
.PHONY: $(1) $(1).all $(1).build $(1).check $(1).clean $(1).showdeliverables $(foreach target,$(gb_Top_MODULE_CHECK_TARGETS),$(1).$(target))

$(1): bootstrap fetch
	cd $(SRCDIR)/$(2) && $$(MAKE) $(IWYU_OPTION) $(PARALLELISM_OPTION) $(GMAKE_OPTIONS)

$(1).build $(1).check $(foreach target,$(gb_Top_MODULE_CHECK_TARGETS),$(1).$(target)): bootstrap fetch
	cd $(SRCDIR)/$(2) && $$(MAKE) $(PARALLELISM_OPTION) $(GMAKE_OPTIONS) $$(patsubst $(1).%,%,$$@)

$(1).clean $(1).showdeliverables:
	cd $(SRCDIR)/$(2) && $$(MAKE) $(PARALLELISM_OPTION) $(GMAKE_OPTIONS) $$(patsubst $(1).%,%,$$@)

$(1).all: bootstrap fetch
	$$(MAKE) $(PARALLELISM_OPTION) $(IWYU_OPTION) $(GMAKE_OPTIONS) -f $(SRCDIR)/Makefile.gbuild $(WORKDIR)/Module/$(1) $(if $(CROSS_COMPILING),,$(WORKDIR)/Module/check/$(1) $(WORKDIR)/Module/slowcheck/$(1))

endef

define gb_Top_GbuildModulesRules
$(foreach m,$(1),$(call gb_Top_GbuildModuleRules,$(notdir $(m)),$(m)))
endef

gbuild_modules := $(patsubst $(SRCDIR)/%/,%,$(dir $(wildcard $(SRCDIR)/*/Module_*.mk $(SRCDIR)/external/*/Module_*.mk)))

gbuild_internal_modules := $(filter-out odk external,$(patsubst $(SRCDIR)/%/,%,$(dir $(wildcard $(SRCDIR)/*/Module_*.mk))))

internal.clean: $(addsuffix .clean,$(gbuild_internal_modules))


$(eval $(call gb_Top_GbuildModulesRules,$(gbuild_modules)))

gbuild_TARGETS := AllLangHelp \
	AllLangMoTarget \
	AllLangPackage \
	AutoInstall \
	CliLibrary \
	CliNativeLibrary \
	CliUnoApi \
	CompilerTest \
	Configuration \
	CppunitTest \
	CustomTarget \
	Dictionary \
	Executable \
	Extension \
	ExtensionPackage \
	ExtensionPackageSet \
	ExternalPackage \
	ExternalProject \
	Gallery \
	GeneratedPackage \
	InstallModule \
	InstallScript \
	InternalUnoApi \
	Jar \
	JunitTest \
	Library \
	Module \
	Package \
	PackageSet \
	Pagein \
	Postprocess \
	Pyuno \
	PythonTest \
	Rdb \
	SdiTarget \
	StaticLibrary \
	UIConfig \
	UITest \
	UnoApi \
	UnpackedTarball \
	WinResTarget \
	Zip \

# build a generic gbuild target
$(foreach target,$(gbuild_TARGETS),$(target)_% $(foreach module,$(gbuild_modules),$(target)_$(module)/%)) UIConfig_modules/% %.genpatch: bootstrap fetch
	$(MAKE) $(PARALLELISM_OPTION) $(GMAKE_OPTIONS) -f $(SRCDIR)/Makefile.gbuild $@

$(gbuild_TARGETS):
	$(MAKE) $(PARALLELISM_OPTION) $(GMAKE_OPTIONS) -f $(SRCDIR)/Makefile.gbuild $@

#
# Clean
#
clean: clean-host clean-build

clean-host:
	rm -fr $(TESTINSTALLDIR)
	rm -fr $(INSTDIR)
	rm -fr $(WORKDIR)

clean-build:
ifneq ($(CROSS_COMPILING),)
	rm -fr $(INSTDIR_FOR_BUILD)
	rm -fr $(WORKDIR_FOR_BUILD)
ifeq ($(OS),ANDROID)
	rm -fr $(SRCDIR)/android/source/obj
	rm -fr $(SRCDIR)/android/source/jniLibs
	rm -fr $(SRCDIR)/android/source/build
	rm -fr $(SRCDIR)/android/source/assets
	rm -fr $(SRCDIR)/android/source/assets_fullUI
	rm -fr $(SRCDIR)/android/source/assets_strippedUI
endif
endif

include $(SRCDIR)/compilerplugins/Makefile.mk

#
# Distclean
#
distclean : clean compilerplugins-clean
	rm -fr \
        $(BUILDDIR)/Makefile \
        $(BUILDDIR)/aclocal.m4 \
        $(BUILDDIR)/autom4te.cache \
        $(BUILDDIR)/bin/bffvalidator.sh \
        $(BUILDDIR)/bin/odfvalidator.sh \
        $(BUILDDIR)/bin/officeotron.sh \
        $(BUILDDIR)/config.log \
        $(BUILDDIR)/config.Build.log \
        $(BUILDDIR)/config.status \
        $(BUILDDIR)/config_build.mk \
        $(BUILDDIR)/config_build_lang.mk \
        $(BUILDDIR)/config_build \
        $(BUILDDIR)/config_host.mk \
        $(BUILDDIR)/config_host.mk.stamp \
        $(BUILDDIR)/config_host_lang.mk \
        $(BUILDDIR)/config_host_lang.mk.stamp \
        $(BUILDDIR)/config_host/*.h \
        $(BUILDDIR)/configure \
        $(BUILDDIR)/instsetoo_native/util/openoffice.lst \
        $(BUILDDIR)/sysui/desktop/macosx/Info.plist
	$(if $(filter WNT,$(OS)),env -i PATH="$$PATH") $(FIND) $(SRCDIR)/solenv/gdb -name \*.pyc -exec rm {} \;

#
# custom command
#
cmd:
	echo "custom cmd" && ( $(cmd) )

#
# Fetch
#
ifneq ($(DO_FETCH_TARBALLS),)
include $(SRCDIR)/Makefile.fetch
fetch: download
fetch: get-submodules

ifneq (,$(wildcard $(SRCDIR)/.git))
get-submodules:
ifneq ($(foreach i,$(GIT_NEEDED_SUBMODULES),$(SRCDIR)/$(i)/.git),$(wildcard $(foreach i,$(GIT_NEEDED_SUBMODULES),$(SRCDIR)/$(i)/.git)))
	cd $(SRCDIR) && ./g -f clone
endif
ifeq ($(shell test -d $(SRCDIR)/.git; echo $$?),0)
	@cd $(SRCDIR) && ./g -z # make sure the git hooks are in place even if no submodules are needed
endif

else # these sources are from a tarball, so get the other source tarballs
gb_LO_VER := $(shell . $(SRCDIR)/sources.ver && echo $$lo_sources_ver)
$(if $(gb_LO_VER),,$(error Error while retrieving $$lo_sources_ver from $(SRCDIR)/sources.ver))

get-submodules: | download
ifneq ($(foreach i,$(subst helpcontent2,help,$(GIT_NEEDED_SUBMODULES)),$(SRCDIR)/src/libreoffice-$(i)-$(gb_LO_VER)),$(wildcard $(foreach i,$(subst helpcontent2,help,$(GIT_NEEDED_SUBMODULES)),$(SRCDIR)/src/libreoffice-$(i)-$(gb_LO_VER))))
	$(foreach i,$(subst helpcontent2,help,$(GIT_NEEDED_SUBMODULES)),\
		$(call fetch_Download_item_unchecked,http://download.documentfoundation.org/libreoffice/src/$(shell echo $(gb_LO_VER) | sed -e "s/\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/"),libreoffice-$(i)-$(gb_LO_VER).tar.xz))
	$(SRCDIR)/bin/unpack-sources $(SRCDIR) $(foreach i,$(subst helpcontent2,help,$(GIT_NEEDED_SUBMODULES)),\
		$(TARFILE_LOCATION)/libreoffice-$(i)-$(gb_LO_VER).tar.xz)
endif

endif

else
fetch:
	@echo "Automatic fetching of external tarballs is disabled."

endif

paul:
	@echo "this is a test from Paul Elijah"


#
# Bootstrap
#
bootstrap: compilerplugins

#
# Build
#
# Note: this will pipe through all gbuild targets to ... gbuild
#       with some translations like "build"->"all" for historic reasons
#
build: bootstrap fetch $(if $(CROSS_COMPILING),cross-toolset) \
        $(if $(filter check,$(MAKECMDGOALS)),$(if $(COMPILER_PLUGINS),$(if $(LODE_HOME),clang-format-check))) \
        install-gdb-printers
	$(MAKE) $(PARALLELISM_OPTION) $(IWYU_OPTION) $(GMAKE_OPTIONS) -f $(SRCDIR)/Makefile.gbuild $(build_goal)
ifeq ($(OS),iOS)
	$(MAKE) $(PARALLELISM_OPTION) $(GMAKE_OPTIONS) ios
endif

build-non-l10n-only build-l10n-only build-nocheck check debugrun translations packageinfo $(gb_Top_MODULE_CHECK_TARGETS): build

help showmodules gbuildtojson:
	$(MAKE) $(PARALLELISM_OPTION) $(GMAKE_OPTIONS) -f $(SRCDIR)/Makefile.gbuild $@

cross-toolset: bootstrap fetch
# fetch again in case there are externals only needed on build platform
ifneq ($(OS),iOS)
	$(MAKE) gb_Side=build $(PARALLELISM_OPTION) $(GMAKE_OPTIONS) -f $(BUILDDIR)/Makefile fetch
endif
	$(MAKE) gb_Side=build $(PARALLELISM_OPTION) $(GMAKE_OPTIONS) -f $(SRCDIR)/Makefile.gbuild build-tools

install-gdb-printers:
ifneq ($(filter-out WNT MACOSX iOS,$(OS)),)
	mkdir -p $(INSTDIR)
	$(SRCDIR)/solenv/bin/install-gdb-printers -a $(INSTDIR) -c
endif


#
# Install
#

define gb_Top_DoInstall
echo "$(1) in $(INSTALLDIR) ..." && \
$(SRCDIR)/solenv/bin/ooinstall $(2) "$(INSTALLDIR)"

endef

ifneq ($(OS),MACOSX)
define gb_Top_InstallFinished
echo && echo "If you want to edit the .ui files with glade first execute:" && \
echo && echo "export GLADE_CATALOG_SEARCH_PATH=$(2)/share/glade" && \
echo && echo "$(1) finished, you can now execute:" && \
echo "$(2)/program/soffice"

endef
else
define gb_Top_InstallFinished
echo && echo "$(1) finished, you can now run: " && \
echo "open $(2)/$(PRODUCTNAME).app" && \
echo "" && \
echo "To debug: gdb $(2)/$(PRODUCTNAME).app/Contents/MacOS/soffice"

endef
endif

ifneq ($(OS),MACOSX)
install:
	@$(call gb_Top_DoInstall,Installing,)
	@$(call gb_Top_InstallFinished,Installation,$(INSTALLDIR))

install-strip:
	@$(call gb_Top_DoInstall,Installing and stripping binaries,--strip)
	@$(call gb_Top_InstallFinished,Installation,$(INSTALLDIR))
endif # !MACOSX

test-install: build
	@rm -rf $(TESTINSTALLDIR)
	@mkdir -p $(TESTINSTALLDIR)
ifeq ($(OS_FOR_BUILD),WNT)
	cd $(SRCDIR)/instsetoo_native && $(MAKE) LIBO_TEST_INSTALL=TRUE $(GMAKE_OPTIONS)
else
	@$(SRCDIR)/solenv/bin/ooinstall $(TESTINSTALLDIR)
ifneq ($(MACOSX_CODESIGNING_IDENTITY),)
#
# Create Resources/*.lproj directories for languages supported by macOS
	set -x; for lang in ca cs da de el en es fi fr hr hu id it ja ko ms nl no pl pt pt_PT ro ru sk sv th tr uk vi zh_CN zh_TW; do \
		lproj=$(TESTINSTALLDIR)/$(PRODUCTNAME_WITHOUT_SPACES).app/Contents/Resources/$$lang.lproj; \
		mkdir "$$lproj"; \
	done
#
# Remove unnecessary executables in the LibreOfficePython framework
	rm -rf $(TESTINSTALLDIR)/$(PRODUCTNAME_WITHOUT_SPACES).app/Contents/Frameworks/LibreOfficePython.framework/Versions/[1-9]*/bin
#
# Remove the python.o object file which is weird and interferes with app store uploading
# And with it removed, presumably the other stuff in the Python lib/python3.3/config-3.3m probably does not make sense either.
	rm -rf $(TESTINSTALLDIR)/$(PRODUCTNAME_WITHOUT_SPACES).app/Contents/Frameworks/LibreOfficePython.framework/Versions/[1-9]*/lib/python[1-9]*/config-[1-9]*
#
ifneq ($(ENABLE_MACOSX_SANDBOX),)

# Remove the gengal binary that we hardly need and the shell scripts
# for which code signatures (stored as extended attributes) won't
# survive upload to the App Store anyway. See
# https://developer.apple.com/library/content/documentation/Security/Conceptual/CodeSigningGuide/Procedures/Procedures.html#//apple_ref/doc/uid/TP40005929-CH4-TNTAG201
# We could put the shell scripts somewhere in Resources instead, but
# no 3rd-party code that would be interested in them would look there
# anyway.
	rm $(TESTINSTALLDIR)/$(PRODUCTNAME_WITHOUT_SPACES).app/Contents/MacOS/gengal
	rm $(TESTINSTALLDIR)/$(PRODUCTNAME_WITHOUT_SPACES).app/Contents/MacOS/unopkg
	rm $(TESTINSTALLDIR)/$(PRODUCTNAME_WITHOUT_SPACES).app/Contents/MacOS/unoinfo
endif
#
# Then use the macosx-codesign-app-bundle script
	@$(SRCDIR)/solenv/bin/macosx-codesign-app-bundle $(TESTINSTALLDIR)/$(PRODUCTNAME_WITHOUT_SPACES).app
endif
endif
	@$(call gb_Top_InstallFinished,Test Installation,$(TESTINSTALLDIR))

mac-app-store-package: test-install
ifneq ($(MACOSX_PACKAGE_SIGNING_IDENTITY),)
	rm -rf "$(PRODUCTNAME).app"
	mv "$(TESTINSTALLDIR)/$(PRODUCTNAME_WITHOUT_SPACES).app" "$(PRODUCTNAME).app"
	productbuild --component "$(PRODUCTNAME).app" /Applications --sign $(MACOSX_PACKAGE_SIGNING_IDENTITY) $(PRODUCTNAME_WITHOUT_SPACES).pkg
else
	@echo You did not provide an installer signing identity with --enable-macosx-package-signing
	@exit 1
endif

distro-pack-install: install
	$(SRCDIR)/bin/distro-install-clean-up
	$(SRCDIR)/bin/distro-install-desktop-integration
	$(SRCDIR)/bin/distro-install-sdk
	$(SRCDIR)/bin/distro-install-file-lists

install-package-%:
	$(MAKE) $(GMAKE_OPTIONS) -f $(SRCDIR)/Makefile.gbuild $@

id:
	@$(SRCDIR)/solenv/bin/create-ids

tags:
	@$(SRCDIR)/solenv/bin/create-tags

etags:
	@$(SRCDIR)/solenv/bin/create-tags -e

docs:
	@$(SRCDIR)/solenv/bin/mkdocs.sh $(SRCDIR)/docs $(SRCDIR)/solenv/inc/doxygen.cfg

findunusedheaders:
	$(SRCDIR)/bin/find-unusedheaders.py

symbols:
	rm -fr $(WORKDIR)/symbols/
	mkdir -p $(WORKDIR)/symbols/
ifeq ($(OS),WNT)
	$(SRCDIR)/bin/symbolstore.py $(WORKDIR)/UnpackedTarball/breakpad/src/tools/windows/binaries/dump_syms.exe $(WORKDIR)/symbols/ $(INSTDIR)/program/*
	$(SRCDIR)/bin/symstore.sh
else
	$(SRCDIR)/bin/symbolstore.py $(WORKDIR)/UnpackedTarball/breakpad/src/tools/linux/dump_syms/dump_syms $(WORKDIR)/symbols/ $(INSTDIR)/program/*
endif

	cd $(WORKDIR)/symbols/ && zip -r $(WORKDIR)/symbols.zip *

create-mar:
	rm -fr $(WORKDIR)/installation/mar/
	rm -fr $(WORKDIR)/installation/temp/
	mkdir -p $(WORKDIR)/installation/temp/
	mkdir -p $(WORKDIR)/installation/mar/
	tar -xzf $(WORKDIR)/installation/LibreOfficeDev/archive/install/en-US/LibreOffice* -C $(WORKDIR)/installation/temp/
	$(SRCDIR)/bin/update/make_full_update.sh $(WORKDIR)/installation/mar/test.mar $(WORKDIR)/installation/temp/*/

upload-symbols:
	$(MAKE) -f $(SRCDIR)/Makefile.gbuild upload-symbols

create-update-info:
	$(MAKE) -f $(SRCDIR)/Makefile.gbuild create-update-info

upload-update-info:
	$(MAKE) -f $(SRCDIR)/Makefile.gbuild upload-update-info

create-partial-info:
	$(MAKE) -f $(SRCDIR)/Makefile.gbuild create-partial-info

dump-deps:
	@$(SRCDIR)/bin/module-deps.pl $(MAKE) $(SRCDIR)/Makefile.gbuild

dump-deps-png:
	@$(SRCDIR)/bin/module-deps.pl $(MAKE) $(SRCDIR)/Makefile.gbuild | dot -Tpng -o lo.png

dump-deps-sort:
	@$(SRCDIR)/bin/module-deps.pl -t $(MAKE) $(SRCDIR)/Makefile.gbuild

clang-format-check:
	@$(SRCDIR)/solenv/clang-format/check-last-commit

define gb_Top_GbuildToIdeIntegration
$(1)-ide-integration: gbuildtojson $(if $(filter MACOSX,$(OS_FOR_BUILD)),python3.all)
	cd $(SRCDIR) && \
		$(if $(filter MACOSX,$(OS_FOR_BUILD)),PATH="$(INSTROOT_FOR_BUILD)/Frameworks/LibreOfficePython.framework/Versions/Current/bin:$(PATH)") \
		$(SRCDIR)/bin/gbuild-to-ide --ide $(1) --make $(MAKE)

endef

$(foreach ide,\
	codelite \
	vs2017 \
	vs2019 \
	kdevelop \
	vim \
	qtcreator \
	xcode \
        eclipsecdt,\
$(eval $(call gb_Top_GbuildToIdeIntegration,$(ide))))

fuzzers: Library_sal Library_salhelper Library_reg Library_store Library_unoidl codemaker Library_cppu Library_i18nlangtag Library_cppuhelper Library_comphelper StaticLibrary_ulingu StaticLibrary_findsofficepath Library_tl Library_basegfx Library_canvastools Library_cppcanvas Library_dbtools Library_deploymentmisc Library_editeng Library_fwe Library_fwi Library_i18nutil Library_localebe1 Library_sax Library_sofficeapp Library_ucbhelper Rdb_services udkapi offapi Library_gie Library_icg Library_reflection Library_invocadapt Library_bootstrap Library_introspection Library_stocservices Library_xmlreader Library_gcc3_uno instsetoo_native more_fonts StaticLibrary_boost_locale StaticLibrary_fuzzerstubs StaticLibrary_fuzzer_core StaticLibrary_fuzzer_calc StaticLibrary_fuzzer_draw StaticLibrary_fuzzer_writer StaticLibrary_fuzzer_math Library_forui Library_binaryurp Library_io Library_invocation Library_namingservice Library_proxyfac Library_uuresolver Module_ure Executable_pptfuzzer Executable_cgmfuzzer Executable_ww2fuzzer Executable_ww6fuzzer Executable_ww8fuzzer Executable_qpwfuzzer Executable_slkfuzzer Executable_fodtfuzzer Executable_fodsfuzzer Executable_fodpfuzzer Executable_xlsfuzzer Executable_scrtffuzzer Executable_wksfuzzer Executable_diffuzzer Executable_docxfuzzer Executable_xlsxfuzzer Executable_pptxfuzzer Executable_htmlfuzzer Executable_rtffuzzer Executable_mmlfuzzer Executable_mtpfuzzer Executable_olefuzzer Executable_lwpfuzzer Executable_hwpfuzzer Executable_wmffuzzer Executable_dxffuzzer Executable_sftfuzzer Executable_svmfuzzer Executable_tiffuzzer Executable_epsfuzzer Executable_jpgfuzzer Executable_metfuzzer Executable_bmpfuzzer Executable_giffuzzer Executable_pngfuzzer Executable_602fuzzer Executable_tgafuzzer Executable_pcxfuzzer Executable_psdfuzzer Executable_ppmfuzzer Executable_pcdfuzzer Executable_rasfuzzer Executable_pctfuzzer Executable_xpmfuzzer Executable_xbmfuzzer

endif # MAKE_RESTARTS

# vim: set noet sw=4 ts=4:
