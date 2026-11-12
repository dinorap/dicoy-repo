THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:latest:15.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = zDiCoyKeyGuard

zDiCoyKeyGuard_FILES = Tweak.x
zDiCoyKeyGuard_CFLAGS = -fobjc-arc
zDiCoyKeyGuard_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
