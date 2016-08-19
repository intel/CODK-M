TOP_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CODK_SW_URL := https://github.com/01org/CODK-A-Software.git
CODK_SW_DIR := $(TOP_DIR)/software
CODK_SW_TAG ?= master
CODK_FW_URL := https://github.com/01org/CODK-M-Firmware.git
CODK_FW_DIR := $(TOP_DIR)/firmware
CODK_FW_TAG ?= master
CODK_X86_URL := https://github.com/01org/CODK-M-X86-Samples.git
CODK_X86_DIR := $(TOP_DIR)/x86-samples
CODK_X86_TAG ?= master
CODK_FLASHPACK_URL := https://github.com/01org/CODK-Z-Flashpack.git
CODK_FLASHPACK_DIR := $(TOP_DIR)/flashpack
CODK_FLASHPACK_TAG := master
ZEPHYR_DIR := $(TOP_DIR)/../zephyr
ZEPHYR_DIR_REL = $(shell $(CODK_FLASHPACK_DIR)/relpath "$(TOP_DIR)" "$(ZEPHYR_DIR)")
ZEPHYR_VER := 1.4.0
ZEPHYR_SDK_VER := 0.8.1
OUT_DIR = $(TOP_DIR)/out

export CODK_DIR ?= $(TOP_DIR)
FWPROJ_DIR ?= $(CODK_FW_DIR)
SWPROJ_DIR ?= $(CODK_SW_DIR)/examples/Blink/

help:

check-root:
	@if [ `whoami` != root ]; then echo "Please run as sudoer/root" && exit 1 ; fi

install-dep: check-root
	$(MAKE) install-dep -C $(CODK_SW_DIR)
	apt-get install -y git make gcc gcc-multilib g++ libc6-dev-i386 g++-multilib python3-ply
	cp -f $(CODK_FLASHPACK_DIR)/drivers/rules.d/*.rules /etc/udev/rules.d/

setup: clone firmware-setup software-setup

clone: $(CODK_SW_DIR) $(CODK_FW_DIR) $(CODK_X86_DIR) $(CODK_FLASHPACK_DIR)

$(CODK_SW_DIR):
	git clone -b $(CODK_SW_TAG) $(CODK_SW_URL) $(CODK_SW_DIR)

$(CODK_FW_DIR):
	git clone -b $(CODK_FW_TAG) $(CODK_FW_URL) $(CODK_FW_DIR)

$(CODK_X86_DIR):
	git clone -b $(CODK_X86_TAG) $(CODK_X86_URL) $(CODK_X86_DIR)

$(CODK_FLASHPACK_DIR):
	git clone -b $(CODK_FLASHPACK_TAG) $(CODK_FLASHPACK_URL) $(CODK_FLASHPACK_DIR)

check-source:
	@if [ -z "$(value ZEPHYR_BASE)" ]; then echo "Please run: source $(ZEPHYR_DIR_REL)/zephyr-env.sh" ; exit 1 ; fi

firmware-setup:
	@echo "Setting up firmware"
	@$(CODK_FLASHPACK_DIR)/install-zephyr.sh $(ZEPHYR_VER) $(ZEPHYR_SDK_VER)

software-setup:
	@echo "Setting up software"
	@$(MAKE) -C $(CODK_SW_DIR) setup

compile: compile-firmware compile-software

compile-firmware: $(OUT_DIR) check-source
	make O=$(OUT_DIR)/firmware BOARD=arduino_101_factory ARCH=x86 -C $(FWPROJ_DIR)

$(OUT_DIR):
	mkdir $(TOP_DIR)/out

compile-software:
	CODK_DIR=$(CODK_DIR) $(MAKE) -C $(SWPROJ_DIR) compile

upload: upload-dfu

upload-dfu: upload-firmware-dfu upload-software-dfu

upload-firmware-dfu:
	$(CODK_FLASHPACK_DIR)/flash_dfu.sh -x $(OUT_DIR)/firmware/zephyr.bin

upload-software-dfu:
	CODK_DIR=$(CODK_DIR) $(MAKE) -C $(SWPROJ_DIR) upload

upload-jtag: upload-firmware-jtag upload-software-jtag

upload-firmware-jtag:
	$(CODK_FLASHPACK_DIR)/flash_jtag.sh -x $(OUT_DIR)/firmware/zephyr.bin

upload-software-jtag:
	# To-do

clean: clean-firmware clean-software

clean-firmware:
	-rm -rf $(OUT_DIR)

clean-software:
	$(MAKE) -C $(SWPROJ_DIR) clean-all

debug-server:
	$(CODK_FLASHPACK_DIR)/bin/openocd -f $(CODK_FLASHPACK_DIR)/scripts/interface/ftdi/flyswatter2.cfg -f $(CODK_FLASHPACK_DIR)/scripts/board/quark_se.cfg

debug-firmware:
	gdb $(OUT_DIR)/firmware/zephyr.elf

debug-software:
	$(CODK_SW_DIR)/arc32/bin/arc-elf32-gdb $(SWPROJ_DIR)/arc-debug.elf
