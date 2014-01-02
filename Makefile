THEOS_DEVICE_IP:=192.168.10.6

iphone:=$(THEOS_DEVICE_IP)
APP_ID = com.jmdasilvas.cariphone2

export THEOS=/toolchain4/theos
export SDKBINPATH=/toolchain4/pre/bin
export SYSROOT=/toolchain4/sys50
export TARGET=iphone:latest:5.0

MINIMUMVERSION:=5000
DEPLOYMENTTARGET:=$(MINIMUMVERSION)
TOOLCHAIN:=/toolchain4

include $(THEOS)/makefiles/common.mk




TWEAK_NAME = docked2
docked2_FILES = Tweak.xm mouse_msgs.mm calibration.mm
docked2_CFLAGS = -F$(SYSROOT)/System/Library/CoreServices

docked2_CFLAGS += -D__IPHONE_OS_VERSION_MIN_REQUIRED=$(MINIMUMVERSION)
docked2_LDFLAGS = -lactivator

docked2_FRAMEWORKS = UIKit CoreFoundation Foundation QuartzCore CoreGraphics IOKit MediaPlayer #BackBoardServices
docked2_PRIVATE_FRAMEWORKS = Celestial GraphicsServices  


include $(THEOS)/makefiles/tweak.mk

export ARCHS =

# Uncomment the following lines when compiling with self-built version of LLVM/Clang
export GO_EASY_ON_ME = 1
export SDKTARGET = $(TOOLCHAIN)/pre/bin/arm-apple-darwin9
export TARGET_CXX = clang -ccc-host-triple arm-apple-darwin9 
export TARGET_LD = $(SDKTARGET)-g++

sync: stage
	rsync -z _/Library/MobileSubstrate/DynamicLibraries/* root@iphone:/Library/MobileSubstrate/DynamicLibraries/
	ssh root@iphone killall SpringBoard

distclean: clean
	- rm -f $(THEOS_PROJECT_DIR)/$(APP_ID)*.deb
	- rm -f $(THEOS_PROJECT_DIR)/.theos/packages/*

