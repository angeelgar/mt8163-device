LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_SUFFIX := 
LOCAL_FORCE_STATIC_EXECUTABLE := true

include $(BUILD_SYSTEM)/binary.mk

$(LOCAL_BUILT_MODULE) : PRIVATE_ELF_FILE := $(intermediates)/$(PRIVATE_MODULE).elf
ifeq ($(TARGET_ARCH),arm)
$(LOCAL_BUILT_MODULE) : PRIVATE_LIBS := `$(TARGET_CC) -mthumb-interwork -print-libgcc-file-name`
else
$(LOCAL_BUILT_MODULE) : PRIVATE_LIBS := `$(TARGET_CC) -print-libgcc-file-name`
endif

$(all_objects) : PRIVATE_TARGET_PROJECT_INCLUDES :=
$(all_objects) : PRIVATE_TARGET_C_INCLUDES :=
$(all_objects) : PRIVATE_TARGET_GLOBAL_CFLAGS :=
$(all_objects) : PRIVATE_TARGET_GLOBAL_CPPFLAGS :=

# support Mac OS and Linux OS
ifeq ($(HOST_OS),darwin)
MTEE_IMG_PROT_TOOL := device/mediatek/build/build/tools/MteeImgSignEncTool/MteeImgSignEncTool.darwin
else
MTEE_IMG_PROT_TOOL := device/mediatek/build/build/tools/MteeImgSignEncTool/MteeImgSignEncTool.linux
endif

TRUSTZONE_BIN := $(PRODUCT_OUT)/$(LOCAL_MODULE)
TMP_TRUSTZONE_BIN := $(PRODUCT_OUT)/$(addprefix tmp_,$(LOCAL_MODULE))
MTEE_IMG_PROT_CFG := bootable/bootloader/preloader/custom/$(MTK_TARGET_PROJECT)/inc/TRUSTZONE_IMG_PROTECT_CFG.ini
ifeq ($(wildcard $(MTEE_IMG_PROT_CFG)),)
MTEE_IMG_PROT_CFG := vendor/mediatek/proprietary/trustzone/mtk/cfg/$(MTK_PLATFORM_LC)/TRUSTZONE_IMG_PROTECT_CFG.ini
endif
ifeq ($(wildcard $(MTEE_IMG_PROT_CFG)),)
MTEE_IMG_PROT_CFG := vendor/mediatek/proprietary/trustzone/cfg/TRUSTZONE_IMG_PROTECT_CFG.ini
endif

MK_IMG_TOOL := $(HOST_OUT_EXECUTABLES)/mkimage

MTK_TRUSTZONE_CFG_FOLDER := vendor/mediatek/proprietary/trustzone/project
PRJ_COMMON := $(MTK_TRUSTZONE_CFG_FOLDER)/common.mk
PRJ_CHIP := $(MTK_TRUSTZONE_CFG_FOLDER)/$(MTK_PLATFORM_LC).mk
PRJ_BASE := $(MTK_TRUSTZONE_CFG_FOLDER)/$(MTK_BASE_PROJECT).mk
PRJ_MF := $(MTK_TRUSTZONE_CFG_FOLDER)/$(MTK_TARGET_PROJECT).mk
MTEE_IMG_CUS_MK :=
ifneq ($(wildcard $(PRJ_COMMON)),)
MTEE_IMG_CUS_MK += $(PRJ_COMMON)
endif
ifneq ($(wildcard $(PRJ_CHIP)),)
MTEE_IMG_CUS_MK += $(PRJ_CHIP)
endif
ifneq ($(wildcard $(PRJ_BASE)),)
MTEE_IMG_CUS_MK += $(PRJ_BASE)
endif
ifneq ($(wildcard $(PRJ_MF)),)
MTEE_IMG_CUS_MK += $(PRJ_MF)
endif

.PHONY: tee_executable_binary sign_tee
$(LOCAL_BUILT_MODULE): PRIVATE_BINARY := $(intermediates)/$(PRIVATE_MODULE)
ifeq ($(TARGET_ARCH),arm)
$(LOCAL_BUILT_MODULE): tee_executable_binary sign_tee
sign_tee: tee_executable_binary
else
$(LOCAL_BUILT_MODULE): tee_executable_binary
endif

tee_executable_binary: $(all_objects) $(all_libraries)
tee_executable_binary: $(MTEE_IMG_CUS_MK) $(MTEE_IMG_PROT_TOOL) $(MK_IMG_TOOL)
	@$(mkdir -p $(dir $@)
	@echo "target Linking: $(PRIVATE_MODULE)"
	$(hide) $(TARGET_LD) \
		$(addprefix --script ,$(PRIVATE_LINK_SCRIPT)) \
		$(PRIVATE_RAW_EXECUTABLE_LDFLAGS) \
		-o $(PRIVATE_ELF_FILE) \
		$(PRIVATE_ALL_OBJECTS) \
                --whole-archive $(filter-out %$(TZ_C_LIBRARIES).a,$(PRIVATE_ALL_STATIC_LIBRARIES)) --no-whole-archive \
		--start-group $(filter-out %$(COMPILER_RT_CONFIG_EXTRA_STATIC_LIBRARIES).a,$(filter %$(TZ_C_LIBRARIES).a,$(PRIVATE_ALL_STATIC_LIBRARIES)))  \
		$(PRIVATE_LIBS) --end-group
	$(hide) $(TARGET_OBJCOPY) -O binary $(PRIVATE_ELF_FILE) $(PRIVATE_BINARY)

sign_tee: $(MTEE_IMG_PROT_CFG)
	@echo "protecting mtee image ($(PRIVATE_BINARY) -> $(TMP_TRUSTZONE_BIN))"
	$(MTEE_IMG_PROT_TOOL) $< $(PRIVATE_BINARY) $(TMP_TRUSTZONE_BIN) $(MEMSIZE)
	@echo "generating mtee image ($(TMP_TRUSTZONE_BIN) -> $(TRUSTZONE_BIN))"
	$(hide) $(MK_IMG_TOOL) $(TMP_TRUSTZONE_BIN) TEE 0xffffffff > $(TRUSTZONE_BIN)
	$(hide) rm $(TMP_TRUSTZONE_BIN)
#	$(hide) $(MK_IMG_TOOL) $@ TEE 0xffffffff > $(TRUSTZONE_BIN)

$(TRUSTZONE_BIN): $(LOCAL_BUILT_MODULE)
