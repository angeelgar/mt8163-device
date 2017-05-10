# Use the non-open-source part, if present
-include vendor/wisky/wisky8163_tb_eg/BoardConfigVendor.mk

# Use the 8163 common part
include device/mediatek/mt8163/BoardConfig.mk

#Config partition size
-include $(MTK_PTGEN_OUT)/partition_size.mk
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_FLASH_BLOCK_SIZE := 4096

include device/wisky/$(MTK_TARGET_PROJECT)/ProjectConfig.mk

MTK_INTERNAL_CDEFS := $(foreach t,$(AUTO_ADD_GLOBAL_DEFINE_BY_NAME),$(if $(filter-out no NO none NONE false FALSE,$($(t))),-D$(t)))
MTK_INTERNAL_CDEFS += $(foreach t,$(AUTO_ADD_GLOBAL_DEFINE_BY_VALUE),$(if $(filter-out no NO none NONE false FALSE,$($(t))),$(foreach v,$(shell echo $($(t)) | tr '[a-z]' '[A-Z]'),-D$(v))))
MTK_INTERNAL_CDEFS += $(foreach t,$(AUTO_ADD_GLOBAL_DEFINE_BY_NAME_VALUE),$(if $(filter-out no NO none NONE false FALSE,$($(t))),-D$(t)=\"$($(t))\"))

COMMON_GLOBAL_CFLAGS += $(MTK_INTERNAL_CDEFS)
COMMON_GLOBAL_CPPFLAGS += $(MTK_INTERNAL_CDEFS)

ifneq ($(MTK_K64_SUPPORT), yes)
BOARD_KERNEL_CMDLINE = bootopt=64S3,32S1,32S1
else
BOARD_KERNEL_CMDLINE = bootopt=64S3,32N2,64N2
endif

# Phase 1 solution for IPOH + Phone encryption (ALPS01800381)
# Adjust partition to enlarge userdata for CTS (ALPS01808326)
# Tablet (ALPS01821753)
# BOARD_MTK_SYSTEM_SIZE_KB :=1155072
BOARD_MTK_SYSTEM_SIZE_KB :=2621440
BOARD_MTK_CACHE_SIZE_KB :=430080
BOARD_MTK_USERDATA_SIZE_KB :=1081344
-include device/mediatek/build/build/tools/base_rule_remake.mk
