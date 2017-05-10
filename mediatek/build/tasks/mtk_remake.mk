ifdef base-rules-hook
ifdef base-rules-remake-module-hook
ifeq ($(strip $(MTK_REMAKE_FLAG)),yes)

# only work in full build
.PHONY: mtk-remake-dump
mtk-remake-dump:
$(DEFAULT_GOAL) all_modules: mtk-remake-dump


# $(1): LOCAL_MODULE_MAKEFILE
# $(2): output file
define mtk-remake-parse-options
mtk-remake-dump: $(2)
$(2): $(1) $$(MTK_REMAKE_PREVIOUS_FEATURE_OPTION_FILE) device/mediatek/build/build/tools/mtk_remake_parse_options.pl
	@echo $$@: $$?
	$(hide) perl device/mediatek/build/build/tools/mtk_remake_parse_options.pl $(2) $(1) $$(MTK_REMAKE_PREVIOUS_FEATURE_OPTION_FILE)

endef


MTK_ALL_MODULE_MAKEFILES := $(sort $(foreach m,$(ALL_MODULES),$(ALL_MODULES.$(m).MAKEFILE)))
MTK_ALL_INCLUDED_MAKEFILES := $(sort $(MTK_ALL_MODULE_MAKEFILES) $(foreach r,$(MTK_ALL_MODULE_MAKEFILES),$(MTK_ALL_MODULE_MAKEFILES.$(r).INCLUDED)))
$(foreach r,$(MTK_ALL_INCLUDED_MAKEFILES),\
  $(eval d := $(MTK_REAMKE_MODULE_DEPENDENCIES_OUT)/$(subst /,_,$(r)).dep)\
  $(eval $(call mtk-remake-parse-options,$(r),$(d)))\
)


ifeq ($(filter update-modem pl preloader lk kernel trustzone,$(MAKECMDGOALS)),)
ifeq ($(ONE_SHOT_MAKEFILE)$(dont_bother),)
ifneq ($(wildcard $(MTK_REMAKE_PREVIOUS_PROJECT_CONFIG_FILE)),)
$(info MTK_REMAKE_CURRENT_PROJECT_CONFIG_DEPENDENCIES = $(MTK_REMAKE_CURRENT_PROJECT_CONFIG_DEPENDENCIES))
$(info MTK_REMAKE_CHANGED_PROJECT_CONFIG_OPTIONS = $(strip $(MTK_REMAKE_CHANGED_PROJECT_CONFIG_OPTIONS)))
$(info MTK_REMAKE_DELETED_PROJECT_CONFIG_OPTIONS = $(strip $(MTK_REMAKE_DELETED_PROJECT_CONFIG_OPTIONS)))
$(info MTK_REMAKE_ADDED_PROJECT_CONFIG_OPTIONS = $(strip $(MTK_REMAKE_ADDED_PROJECT_CONFIG_OPTIONS)))
$(info MTK_REMAKE_DELETED_PRODUCT_CONFIG_OPTIONS = $(strip $(MTK_REMAKE_DELETED_PRODUCT_CONFIG_OPTIONS)))
$(info MTK_REMAKE_ADDED_PRODUCT_CONFIG_OPTIONS = $(strip $(MTK_REMAKE_ADDED_PRODUCT_CONFIG_OPTIONS)))
$(info MTK_REMAKE_CHANGED_COMMON_GLOBAL_CFLAGS = $(strip $(MTK_REMAKE_CHANGED_COMMON_GLOBAL_CFLAGS)))
$(info MTK_REMAKE_CHANGED_COMMON_PRODUCT_VARS = $(strip $(MTK_REMAKE_CHANGED_COMMON_PRODUCT_VARS)))
$(foreach l,$(MTK_REMAKE_PREVIOUS_PROJECT_CONFIG_TEXT),\
  $(eval k := $(firstword $(subst =,$(space),$(l))))\
  $(eval v := $(strip $(subst ?,$(space),$(patsubst $(k)=%,%,$(l)))))\
  $(eval f := $(strip $(subst ?,$(space),$(k))))\
  $(if $(filter $(f),$(_product_var_list)),\
    $(if $(strip $(filter-out $(PRODUCTS.$(INTERNAL_PRODUCT).$(f)),$(v))$(filter-out $(v),$(PRODUCTS.$(INTERNAL_PRODUCT).$(f)))),\
      $(info $(f) = $(filter-out $(v),$(PRODUCTS.$(INTERNAL_PRODUCT).$(f))) <= $(filter-out $(PRODUCTS.$(INTERNAL_PRODUCT).$(f)),$(v)))\
    )\
  ,\
    $(if $(filter $(f),$(MTK_REMAKE_CURRENT_PROJECT_CONFIG_OPTIONS)),\
      $(if $(strip $(filter-out $($(f)),$(v))$(filter-out $(v),$($(f)))),\
        $(info $(f) = $($(f)) <= $(v))\
      )\
    ,\
      $(if $(filter $(f),ALL_MODULES),\
        $(if $(strip $(filter-out $($(f)),$(v))$(filter-out $(v),$($(f)))),\
          $(eval MTK_REMAKE_CHANGED_PROJECT_CONFIG_OPTIONS += $(f))\
          $(info $(f) = $(filter-out $(v),$($(f))) <= $(filter-out $($(f)),$(v)))\
          $(eval MTK_REMAKE_DELETED_ALL_MODULES := $(filter-out $($(f)),$(v)))\
        )\
      )\
    )\
  )\
)
endif


# installclean
ifneq ($(filter $(_product_var_list),$(filter-out PRODUCT_PROPERTY_OVERRIDES,$(MTK_REMAKE_DELETED_PRODUCT_CONFIG_OPTIONS)))$(strip $(MTK_REMAKE_DELETED_ALL_MODULES)),)
ifeq ($(filter-out $(INTERNAL_MODIFIER_TARGETS) dist,$(MAKECMDGOALS)),)
  $(info *** rm -rf $(installclean_files))
  $(shell rm -rf $(installclean_files))
endif
endif
ifneq ($(strip $(MTK_REMAKE_DELETED_ALL_MODULES)),)
  intermediates_clean_files := \
    $(foreach m,$(MTK_REMAKE_DELETED_ALL_MODULES),\
      $(foreach c,EXECUTABLES SHARED_LIBRARIES STATIC_LIBRARIES APPS JAVA_LIBRARIES ETC FAKE NOTICE_FILES PACKAGING,\
        $(call intermediates-dir-for,$(c),$(m))\
        $(call intermediates-dir-for,$(c),$(m),,,2ND_)\
        $(call intermediates-dir-for,$(c),$(m),HOST)\
        $(call intermediates-dir-for,$(c),$(m),HOST,,2ND_)\
        $(call intermediates-dir-for,$(c),$(m),,COMMON)\
        $(call intermediates-dir-for,$(c),$(m),HOST,COMMON)\
      )\
    )
  $(info *** rm -rf $(intermediates_clean_files))
  $(shell rm -rf $(intermediates_clean_files))
endif
ifneq ($(filter $(_product_var_list),$(MTK_REMAKE_DELETED_PRODUCT_CONFIG_OPTIONS) $(MTK_REMAKE_ADDED_PRODUCT_CONFIG_OPTIONS)),)
  $(info .PHONY: $(intermediate_system_build_prop))
  .PHONY: $(intermediate_system_build_prop)
endif


mtk-remake-dump: $(MTK_REMAKE_PREVIOUS_PROJECT_CONFIG_FILE)
$(MTK_REMAKE_PREVIOUS_PROJECT_CONFIG_FILE): PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS := $(filter-out $(_product_var_list),$(MTK_REMAKE_CURRENT_PROJECT_CONFIG_OPTIONS))
$(MTK_REMAKE_PREVIOUS_PROJECT_CONFIG_FILE): $(MTK_REMAKE_CURRENT_PROJECT_CONFIG_DEPENDENCIES)
ifneq ($(strip $(MTK_REMAKE_CHANGED_PROJECT_CONFIG_OPTIONS) $(MTK_REMAKE_DELETED_PROJECT_CONFIG_OPTIONS) $(MTK_REMAKE_ADDED_PROJECT_CONFIG_OPTIONS) $(MTK_REMAKE_DELETED_PRODUCT_CONFIG_OPTIONS) $(MTK_REMAKE_ADDED_PRODUCT_CONFIG_OPTIONS)),)
$(MTK_REMAKE_PREVIOUS_PROJECT_CONFIG_FILE): FORCE
endif
	@echo $@: $?
	@mkdir -p $(dir $@)
	@rm -f $@
	@$(foreach f,$(_product_var_list),echo '$(f)=$(PRODUCTS.$(INTERNAL_PRODUCT).$(f))' >>$@;)
	@$(foreach f,ALL_MODULES,echo '$(f)=$($(f))' >>$@;)
	@$(foreach f,$(wordlist    1, 100,$(PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)=$($(f))' >>$@;)
	@$(foreach f,$(wordlist  101, 200,$(PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)=$($(f))' >>$@;)
	@$(foreach f,$(wordlist  201, 300,$(PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)=$($(f))' >>$@;)
	@$(foreach f,$(wordlist  301, 400,$(PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)=$($(f))' >>$@;)
	@$(foreach f,$(wordlist  401, 500,$(PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)=$($(f))' >>$@;)
	@$(foreach f,$(wordlist  501, 600,$(PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)=$($(f))' >>$@;)
	@$(foreach f,$(wordlist  601, 700,$(PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)=$($(f))' >>$@;)
	@$(foreach f,$(wordlist  701, 800,$(PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)=$($(f))' >>$@;)
	@$(foreach f,$(wordlist  801, 900,$(PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)=$($(f))' >>$@;)
	@$(foreach f,$(wordlist  901,1000,$(PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)=$($(f))' >>$@;)
	@$(foreach f,$(wordlist 1001,1100,$(PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)=$($(f))' >>$@;)
	@$(foreach f,$(wordlist 1101,1200,$(PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)=$($(f))' >>$@;)
	@$(if        $(wordlist 1201,1202,$(PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS)),$(error Too many feature options ($(words $(PRIVATE_CURRENT_PROJECT_CONFIG_OPTIONS)))))


mtk-remake-dump: $(MTK_REMAKE_PREVIOUS_FEATURE_OPTION_FILE)
$(MTK_REMAKE_PREVIOUS_FEATURE_OPTION_FILE): $(MTK_REMAKE_CURRENT_PROJECT_CONFIG_DEPENDENCIES)
ifneq ($(strip $(MTK_REMAKE_DELETED_PROJECT_CONFIG_OPTIONS) $(MTK_REMAKE_ADDED_PROJECT_CONFIG_OPTIONS)),)
$(MTK_REMAKE_PREVIOUS_FEATURE_OPTION_FILE): FORCE
endif
	@echo $@: $?
	@mkdir -p $(dir $@)
	@rm -f $@
	@$(foreach f,$(wordlist    1, 200,$(MTK_REMAKE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)' >>$@;)
	@$(foreach f,$(wordlist  201, 400,$(MTK_REMAKE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)' >>$@;)
	@$(foreach f,$(wordlist  401, 600,$(MTK_REMAKE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)' >>$@;)
	@$(foreach f,$(wordlist  601, 800,$(MTK_REMAKE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)' >>$@;)
	@$(foreach f,$(wordlist  801,1000,$(MTK_REMAKE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)' >>$@;)
	@$(foreach f,$(wordlist 1001,1200,$(MTK_REMAKE_CURRENT_PROJECT_CONFIG_OPTIONS)),echo '$(f)' >>$@;)
	@$(if        $(wordlist 1201,1202,$(MTK_REMAKE_CURRENT_PROJECT_CONFIG_OPTIONS)),$(error Too many feature options ($(words $(MTK_REMAKE_CURRENT_PROJECT_CONFIG_OPTIONS)))))


else#ONE_SHOT_MAKEFILE
$(info Skip MTK remake when ONE_SHOT_MAKEFILE = $(ONE_SHOT_MAKEFILE))
endif#ONE_SHOT_MAKEFILE
endif#MAKECMDGOALS

ifneq ($(wildcard $(MTK_PTGEN_OUT)/partition_size.mk),)
ifeq ($(wildcard $(PRODUCT_OUT)/$(MTK_PTGEN_CHIP)_Android_scatter.txt),)
  $(info .PHONY: $(MTK_PTGEN_OUT)/partition_size.mk - due to missing $(PRODUCT_OUT)/$(MTK_PTGEN_CHIP)_Android_scatter.txt)
  .PHONY: $(MTK_PTGEN_OUT)/partition_size.mk
endif
endif

endif#MTK_REMAKE_FLAG
endif#base-rules-remake-module-hook
endif#base-rules-hook
