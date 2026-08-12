_INC_MK_GO_ROOT_DIR_SLASH := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
_INC_MK_GO_ROOT_DIR := $(_INC_MK_GO_ROOT_DIR_SLASH:/=)

include $(_INC_MK_GO_ROOT_DIR)/makefile-common/*.mk
include $(_INC_MK_GO_ROOT_DIR)/*.mk