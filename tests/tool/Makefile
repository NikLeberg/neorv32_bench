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
	$(info Test if various tools are able to elaborate and simulate a core.)
	$(info available tools are: nvc, questa, ghdl)
	$(info run with: `make <tool> test`)
