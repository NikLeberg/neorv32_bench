# SPDX-License-Identifier: MIT

PROJ_ROOT ?= $(abspath ../..)
include $(PROJ_ROOT)/scripts/makefile.tools

# Swallow unknown targets and "nothing to be done for x" messages.
%:
	$(info warning: ignored target '$*'.)

# Print help message and usage instructions.
.DEFAULT_GOAL := help
.PHONY: help
help:
	$(info Formally verify neorv32 entities.)
	$(info run with: `make formal test`)
