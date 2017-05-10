# mt8163 platform boardconfig

# Use the non-open-source part, if present
-include vendor/mediatek/mt8163/BoardConfigVendor.mk

# Use the common part
include device/mediatek/common/BoardConfig.mk

ifneq ($(MTK_K64_SUPPORT), yes)
TARGET_ARCH := arm
TARGET_CPU_VARIANT := cortex-a7
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_SMP := true
TARGET_ARCH_VARIANT := armv7-a-neon

TARGET_2ND_CPU_VARIANT := cortex-a53
else
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
ifeq ($(strip $(MTK_BASIC_PACKAGE)),yes)
TARGET_CPU_VARIANT := generic
else
TARGET_CPU_VARIANT := cortex-a53
endif
TARGET_CPU_SMP := true

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
ifneq ($(MAKECMDGOALS),cts)
ifeq ($(strip $(MTK_BASIC_PACKAGE)),yes)
TARGET_2ND_CPU_VARIANT := cortex-a7
else
TARGET_2ND_CPU_VARIANT := cortex-a53
endif
else
TARGET_2ND_CPU_VARIANT := cortex-a7
endif

TARGET_TOOLCHAIN_ROOT := prebuilts/gcc/$(HOST_PREBUILT_TAG)/aarch64/aarch64-linux-android-4.9
TARGET_TOOLS_PREFIX := $(TARGET_TOOLCHAIN_ROOT)/bin/aarch64-linux-android-

#TARGET_TOOLCHAIN_ROOT := prebuilts/gcc/$(HOST_PREBUILT_TAG)/aarch64/cit-aarch64-linux-android-4.9
#TARGET_TOOLS_PREFIX := $(TARGET_TOOLCHAIN_ROOT)/bin/aarch64-linux-android-

#2ND_TARGET_TOOLCHAIN_ROOT := prebuilts/gcc/$(HOST_PREBUILT_TAG)/arm/cit-arm-linux-androideabi-4.8
#2ND_TARGET_TOOLS_PREFIX := $(2ND_TARGET_TOOLCHAIN_ROOT)/bin/arm-linux-androideabi-

KERNEL_CROSS_COMPILE:= $(abspath $(TOP))/$(TARGET_TOOLS_PREFIX)

endif

ARCH_ARM_HAVE_TLS_REGISTER := true
TARGET_BOARD_PLATFORM := mt8163
MTK_PLATFORM := mt8163
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_NO_FACTORYIMAGE:=true
KERNELRELEASE := 3.4

# MTK, Nick Ko, 20140305, Add Display {
TARGET_FORCE_HWC_FOR_VIRTUAL_DISPLAYS := true
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3
TARGET_RUNNING_WITHOUT_SYNC_FRAMEWORK := true
# temporarily avoid ALPS01799495 failed issue in BSP load
ifneq ($(strip $(MTK_BASIC_PACKAGE)),yes)
    VSYNC_EVENT_PHASE_OFFSET_NS := -5000000
    SF_VSYNC_EVENT_PHASE_OFFSET_NS := -5000000
    #PRESENT_TIME_OFFSET_FROM_VSYNC_NS := 0
else
    #VSYNC_EVENT_PHASE_OFFSET_NS := 0
    #SF_VSYNC_EVENT_PHASE_OFFSET_NS := 0
    #PRESENT_TIME_OFFSET_FROM_VSYNC_NS := 0
endif
MTK_HWC_SUPPORT := yes
MTK_HWC_VERSION := 1.4.1
# MTK, Nick Ko, 20140305, Add Display }

BOARD_CONNECTIVITY_VENDOR := MediaTek
BOARD_USES_MTK_AUDIO := true

ifeq ($(MTK_AGPS_APP), yes)
   BOARD_AGPS_SUPL_LIBRARIES := true
else
   BOARD_AGPS_SUPL_LIBRARIES := false
endif

ifeq ($(MTK_GPS_SUPPORT), yes)
  BOARD_GPS_LIBRARIES := true
else
  BOARD_GPS_LIBRARIES := false
endif

ifeq ($(strip $(BOARD_CONNECTIVITY_VENDOR)), MediaTek)

BOARD_CONNECTIVITY_MODULE := conn_soc 
BOARD_MEDIATEK_USES_GPS := true

endif

ifeq ($(MTK_WLAN_SUPPORT), yes)
BOARD_WLAN_DEVICE := MediaTek
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_mt66xx
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_mt66xx
WIFI_DRIVER_FW_PATH_PARAM := /dev/wmtWifi
WIFI_DRIVER_FW_PATH_STA:=STA
WIFI_DRIVER_FW_PATH_AP:=AP
WIFI_DRIVER_FW_PATH_P2P:=P2P
WIFI_DRIVER_STATE_CTRL_PARAM := /dev/wmtWifi
WIFI_DRIVER_STATE_ON := 1
WIFI_DRIVER_STATE_OFF := 0
ifneq ($(strip $(MTK_BSP_PACKAGE)),yes)
MTK_WIFI_CHINESE_SSID := yes
endif
ifeq ($(strip $(MTK_BSP_PACKAGE)),yes)
MTK_WIFI_GET_IMSI_FROM_PROPERTY := yes
endif
endif

# mkbootimg header, which is used in LK
BOARD_KERNEL_BASE = 0x40000000
ifneq ($(MTK_K64_SUPPORT), yes)
BOARD_KERNEL_OFFSET = 0x00008000
else
BOARD_KERNEL_OFFSET = 0x00080000
endif
BOARD_RAMDISK_OFFSET = 0x04000000
BOARD_TAGS_OFFSET = 0xE000000
ifneq ($(MTK_K64_SUPPORT), yes)
BOARD_KERNEL_CMDLINE = bootopt=64S3,32S1,32S1
else
TARGET_USES_64_BIT_BINDER := true
TARGET_IS_64_BIT := true
BOARD_KERNEL_CMDLINE = bootopt=64S3,32N2,64N2
endif
BOARD_MKBOOTIMG_ARGS := --kernel_offset $(BOARD_KERNEL_OFFSET) --ramdisk_offset $(BOARD_RAMDISK_OFFSET) --tags_offset $(BOARD_TAGS_OFFSET)

# Add MTK compile options to wrap MTK's modifications on AOSP.
ifneq ($(MTK_BASIC_PACKAGE), yes)
COMMON_GLOBAL_CFLAGS += -DMTK_AOSP_ENHANCEMENT
COMMON_GLOBAL_CPPFLAGS += -DMTK_AOSP_ENHANCEMENT
endif

pathmap_INCL += trustzone:$(MTK_PATH_SOURCE)/trustzone/mtee/source/common/include
pathmap_INCL += trustzone-uree:$(MTK_PATH_SOURCE)/external/trustzone/mtee/include

BOARD_SEPOLICY_DIRS += device/mediatek/mt8163/sepolicy
BOARD_SEPOLICY_UNION += \
    g3d_device.te \
    gpad.te

ifeq ($(TARGET_BUILD_VARIANT),user)
WITH_DEXPREOPT := true
DONT_DEXPREOPT_PREBUILTS := true
endif
