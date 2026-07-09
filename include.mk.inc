_INC_MK_ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

include $(_INC_MK_ROOT_DIR)/makefile-common/*.mk
include $(_INC_MK_ROOT_DIR)/*.mk