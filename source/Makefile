export TARGET = iphone:clang:15.5:14.0
export ARCHS = arm64

export libcolorpicker_ARCHS = arm64
export libFLEX_ARCHS = arm64
export Alderis_XCODEOPTS = LD_DYLIB_INSTALL_NAME=@rpath/Alderis.framework/Alderis
export Alderis_XCODEFLAGS = DYLIB_INSTALL_NAME_BASE=/Library/Frameworks BUILD_LIBRARY_FOR_DISTRIBUTION=YES ARCHS="$(ARCHS)" -quiet
export libcolorpicker_LDFLAGS = -F$(TARGET_PRIVATE_FRAMEWORK_PATH) -install_name @rpath/libcolorpicker.dylib
export ADDITIONAL_CFLAGS = -I$(THEOS_PROJECT_DIR)/Tweaks/RemoteLog

ifneq ($(JAILBROKEN),1)
export DEBUGFLAG = -ggdb -Wno-unused-command-line-argument -L$(THEOS_OBJ_DIR) -F$(_THEOS_LOCAL_DATA_DIR)/$(THEOS_OBJ_DIR_NAME)/install/Library/Frameworks
MODULES = jailed
endif

ifndef YOUTUBE_VERSION
YOUTUBE_VERSION = 18.14.1
endif
ifndef UYOU_VERSION
UYOU_VERSION = 3.0
endif
PACKAGE_VERSION = $(YOUTUBE_VERSION)-$(UYOU_VERSION)

INSTALL_TARGET_PROCESSES = YouTube
TWEAK_NAME = uYouPlus
DISPLAY_NAME = YouTube
BUNDLE_ID = com.google.ios.youtube

$(TWEAK_NAME)_FILES = uYouPlus.xm Settings.xm
$(TWEAK_NAME)_FRAMEWORKS = UIKit Security
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -DTWEAK_VERSION=\"$(PACKAGE_VERSION)\"
$(TWEAK_NAME)_INJECT_DYLIBS = Tweaks/uYou/Library/MobileSubstrate/DynamicLibraries/uYou.dylib $(THEOS_OBJ_DIR)/libFLEX.dylib $(THEOS_OBJ_DIR)/iSponsorBlock.dylib $(THEOS_OBJ_DIR)/YouPiP.dylib $(THEOS_OBJ_DIR)/YouTubeDislikesReturn.dylib $(THEOS_OBJ_DIR)/YTABConfig.dylib $(THEOS_OBJ_DIR)/YTUHD.dylib $(THEOS_OBJ_DIR)/DontEatMyContent.dylib
$(TWEAK_NAME)_EMBED_LIBRARIES = $(THEOS_OBJ_DIR)/libcolorpicker.dylib
$(TWEAK_NAME)_EMBED_FRAMEWORKS = $(_THEOS_LOCAL_DATA_DIR)/$(THEOS_OBJ_DIR_NAME)/install/Library/Frameworks/Alderis.framework
$(TWEAK_NAME)_EMBED_BUNDLES = $(wildcard Bundles/*.bundle)
$(TWEAK_NAME)_EMBED_EXTENSIONS = $(wildcard Extensions/*.appex)

include $(THEOS)/makefiles/common.mk
ifneq ($(JAILBROKEN),1)
SUBPROJECTS += Tweaks/Alderis Tweaks/FLEXing/libflex Tweaks/iSponsorBlock Tweaks/Return-YouTube-Dislikes Tweaks/YouPiP Tweaks/YTABConfig Tweaks/YTUHD Tweaks/DontEatMyContent
include $(THEOS_MAKE_PATH)/aggregate.mk
endif
include $(THEOS_MAKE_PATH)/tweak.mk

REMOVE_EXTENSIONS = 1
CODESIGN_IPA = 0

UYOU_PATH = Tweaks/uYou
UYOU_DEB = $(UYOU_PATH)/com.miro.uyou_$(UYOU_VERSION)_iphoneos-arm.deb
UYOU_DYLIB = $(UYOU_PATH)/Library/MobileSubstrate/DynamicLibraries/uYou.dylib
UYOU_BUNDLE = $(UYOU_PATH)/Library/Application\ Support/uYouBundle.bundle

internal-clean::
	@rm -rf $(UYOU_PATH)/*

ifneq ($(JAILBROKEN),1)
before-all::
	@if [[ ! -f $(UYOU_DEB) ]]; then \
		rm -rf $(UYOU_PATH)/*; \
		$(PRINT_FORMAT_BLUE) "Downloading uYou"; \
	fi
before-all::
	@if [[ ! -f $(UYOU_DEB) ]]; then \
 		curl -s https://miro92.com/repo/debs/com.miro.uyou_$(UYOU_VERSION)_iphoneos-arm.deb -o $(UYOU_DEB); \
 	fi; \
	if [[ ! -f $(UYOU_DYLIB) || ! -d $(UYOU_BUNDLE) ]]; then \
		tar -xf Tweaks/uYou/com.miro.uyou_$(UYOU_VERSION)_iphoneos-arm.deb -C Tweaks/uYou; tar -xf Tweaks/uYou/data.tar* -C Tweaks/uYou; \
		if [[ ! -f $(UYOU_DYLIB) || ! -d $(UYOU_BUNDLE) ]]; then \
			$(PRINT_FORMAT_ERROR) "Failed to extract uYou"; exit 1; \
		fi; \
	fi;
else
before-package::
	@mkdir -p $(THEOS_STAGING_DIR)/Library/Application\ Support; cp -r lang/uYouPlus.bundle $(THEOS_STAGING_DIR)/Library/Application\ Support/
endif
