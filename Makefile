TOP_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CODK_ARC_URL := https://github.com/01org/CODK-A-ARC.git
CODK_ARC_DIR := $(TOP_DIR)/arc
CODK_ARC_TAG ?= master
CODK_X86_URL := https://github.com/01org/CODK-M-X86.git
CODK_X86_DIR := $(TOP_DIR)/x86
CODK_X86_TAG ?= master
CODK_X86SAMPLES_URL := https://github.com/01org/CODK-M-X86-Samples.git
CODK_X86SAMPLES_DIR := $(TOP_DIR)/x86-samples
CODK_X86SAMPLES_TAG ?= master
ARC_PROJ ?= $(CODK_ARC_DIR)/examples/BareMinimum
X86_PROJ ?= $(CODK_X86SAMPLES_DIR)/Blank
X86SAMPLES_SERVICES_DIR := $(CODK_X86SAMPLES_DIR)/common/arduino101_services
X86SAMPLES_ARDUINO_DIR := $(CODK_X86SAMPLES_DIR)/common/arduino
PROJ_DIR := my_project
CODK_FLASHPACK_URL := https://github.com/01org/CODK-Z-Flashpack.git
CODK_FLASHPACK_DIR := $(TOP_DIR)/flashpack
CODK_FLASHPACK_TAG := master
GEN_USER_ENV := $(CODK_FLASHPACK_DIR)/gen_user_env.sh
BLE_IMAGE  := $(CODK_FLASHPACK_DIR)/images/firmware/ble_core/imagev3.bin
ZEPHYR_DIR := $(TOP_DIR)/../zephyr
ZEPHYR_DIR_REL = $(shell $(CODK_FLASHPACK_DIR)/relpath "$(TOP_DIR)" "$(ZEPHYR_DIR)")
ZEPHYR_VER := 1.7.0
ZEPHYR_SDK_VER := 0.9
OUT_DIR := $(TOP_DIR)/out
OUT_X86_DIR := $(OUT_DIR)/x86
OUT_ARC_DIR := $(OUT_DIR)/arc
PME_LIB_URL := https://github.com/01org/Intel-Pattern-Matching-Technology
PME_LIB_DIR :=$(CODK_ARC_DIR)/corelibs/libraries/Intel-Pattern-Matching-Technology

export CODK_DIR ?= $(TOP_DIR)
X86_PROJ_DIR ?= $(CODK_X86_DIR)
ARC_PROJ_DIR ?= $(CODK_ARC_DIR)/examples/ASCIITable/
SKETCH       ?= $(ARC_PROJ_DIR)/$(shell basename $(ARC_PROJ_DIR)).ino
SKETCH_DIR   := $(dir $(SKETCH))

help:
	@echo
	@echo "CODK-M available targets"
	@echo
	@echo "project            : create new blank project (PROJ_DIR variable must be set)"
	@echo "convert-sketch     : convert *.ino to *.cpp (SKETCH variable must be set)"
	@echo "compile-x86        : compile the x86 application in X86_PROJ_DIR"
	@echo "compile-arc        : compile the ARC application in ARC_PROJ_DIR, with debug"
	@echo "                     symbols disabled and optimisation flags enabled"
	@echo "compile-debug-arc  : compile the ARC application in ARC_PROJ_DIR, with debug"
	@echo "                     symbols enabled and optimisation flags disabled"
	@echo "compile            : compile x86 and ARC applications, with debug symbols"
	@echo "                     disabled and optimisation flags enabled"
	@echo "compile-debug      : compile x86 and ARC applications, with debug symbols"
	@echo "                     enabled and optimisation flags disabled"
	@echo "upload-x86-dfu     : upload the x86 application (USB cable & dfu-util)"
	@echo "upload-arc-dfu     : upload the ARC application (USB cable & dfu-util)"
	@echo "upload             : upload the ARC and x86 applications (USB cable & dfu-util)"
	@echo "upload-x86-jtag    : upload the x86 application using OpenOCD configured  "
	@echo "                     for a Flyswatter2 JTAG debugger"
	@echo "upload-arc-jtag    : upload the ARC application using OpenOCD configured  "
	@echo "                     for a Flyswatter2 JTAG debugger"
	@echo "upload-jtag        : upload the ARC and x86 applications using OpenOCD configured "
	@echo "                     for a Flyswatter2 JTAG debugger"
	@echo "upload-x86-jlink   : upload the x86 application using OpenOCD configured "
	@echo "                     for a Jlink JTAG debugger"
	@echo "upload-arc-jlink   : upload the ARC application using OpenOCD configured "
	@echo "                     for a Jlink JTAG debugger"
	@echo "upload-jlink       : upload the ARC and x86 applications using OpenOCD "
	@echo "                     configured for a Jlink JTAG debugger"
	@echo "upload-ble-dfu     : upload the Nordic BLE firmware (USB cable & dfu-util)"
	@echo "debug-server       : start OpenOCD server, configured for a Flyswatter2 "
	@echo "                     JTAG debugger (deprecated)"
	@echo "debug-server-jtag  : start OpenOCD server, configured for a Flyswatter2 "
	@echo "                     JTAG debugger"
	@echo "debug-server-jlink : start OpenOCD server, configured for a Jlink "
	@echo "                     JTAG debugger"
	@echo "debug-x6           : Debug x86 application with GDB"
	@echo "debug-arc          : Debug ARC application with GDB"
	@echo

check-root:
	@if [ `whoami` != root ]; then echo "Please run as sudoer/root" && exit 1 ; fi

install-dep: check-root
	$(MAKE) install-dep -C $(CODK_ARC_DIR)
	apt-get install -y curl git make gcc gcc-multilib g++ libc6-dev-i386 g++-multilib python3-ply
	dpkg --purge modemmanager
	usermod -a -G dialout $(SUDO_USER)

setup: clone x86-setup arc-setup

clone: $(CODK_ARC_DIR) $(CODK_X86_DIR) $(CODK_X86SAMPLES_DIR) $(CODK_FLASHPACK_DIR)

$(CODK_ARC_DIR):
	git clone -b $(CODK_ARC_TAG) $(CODK_ARC_URL) $(CODK_ARC_DIR)

$(CODK_X86_DIR):
	git clone -b $(CODK_X86_TAG) $(CODK_X86_URL) $(CODK_X86_DIR)

$(CODK_X86SAMPLES_DIR):
	git clone -b $(CODK_X86SAMPLES_TAG) $(CODK_X86SAMPLES_URL) $(CODK_X86SAMPLES_DIR)
	cd $(CODK_X86SAMPLES_DIR) && ./create_symlinks.sh

$(CODK_FLASHPACK_DIR):
	git clone -b $(CODK_FLASHPACK_TAG) $(CODK_FLASHPACK_URL) $(CODK_FLASHPACK_DIR)

check-source:
	@if [ -z "$(value ZEPHYR_BASE)" ]; then echo "Please run: source $(ZEPHYR_DIR_REL)/zephyr-env.sh" ; exit 1 ; fi

x86-setup:
	@echo "Setting up x86 Firmware"
	@$(CODK_FLASHPACK_DIR)/install-zephyr.sh $(ZEPHYR_VER) $(ZEPHYR_SDK_VER)

arc-setup:
	@echo "Setting up ARC Firmware"
	@$(MAKE) -C $(CODK_ARC_DIR) setup CORELIBS_URL=https://github.com/01org/corelibs-arduino101/archive/codk-m.zip
	git clone $(PME_LIB_URL) $(PME_LIB_DIR)

project:
	@if [ -d $(PROJ_DIR) ]; then echo "$(PROJ_DIR) already exists."; exit 1; fi
	@mkdir $(CODK_DIR)/$(PROJ_DIR)
	@cp -r $(ARC_PROJ) $(CODK_DIR)/$(PROJ_DIR)/arc
	@cp -r $(X86_PROJ) $(CODK_DIR)/$(PROJ_DIR)/x86
	@$(GEN_USER_ENV) $(CODK_DIR) $(PROJ_DIR)

compile: compile-x86 compile-arc

compile-x86: $(OUT_DIR) check-source
	make O=$(OUT_X86_DIR)/ BOARD=arduino_101 ARCH=x86 -C $(X86_PROJ_DIR)

$(OUT_DIR):
	mkdir $(TOP_DIR)/out

compile-arc:
	CODK_DIR=$(CODK_DIR) $(MAKE) -C $(ARC_PROJ_DIR) compile

convert-sketch:
	CODK_DIR=$(CODK_DIR) $(MAKE) -C $(SKETCH_DIR) convert-sketch SKETCH=$(notdir $(SKETCH))

compile-debug: compile-x86 compile-debug-arc

compile-debug-arc:
	CODK_DIR=$(CODK_DIR) $(MAKE) -C $(ARC_PROJ_DIR) compile-debug

upload: upload-dfu

upload-dfu: upload-x86-dfu sleepitoff upload-arc-dfu

upload-x86-dfu:
	$(CODK_FLASHPACK_DIR)/flash_dfu.sh -x $(OUT_X86_DIR)/zephyr.bin

upload-arc-dfu:
	CODK_DIR=$(CODK_DIR) $(MAKE) -C $(ARC_PROJ_DIR) upload

sleepitoff:
	sleep 10

upload-jtag: upload-x86-jtag upload-arc-jtag

upload-x86-jtag:
	$(CODK_FLASHPACK_DIR)/flash_jtag.sh -x $(OUT_X86_DIR)/zephyr.bin

upload-arc-jtag:
	$(CODK_FLASHPACK_DIR)/flash_jtag.sh -a $(ARC_PROJ_DIR)/arc.bin

upload-jlink: upload-x86-jlink upload-arc-jlink

upload-x86-jlink:
	$(CODK_FLASHPACK_DIR)/flash_jlink.sh -x $(OUT_X86_DIR)/zephyr.bin

upload-arc-jlink:
	$(CODK_FLASHPACK_DIR)/flash_jlink.sh -a $(ARC_PROJ_DIR)/arc.bin

upload-ble-dfu:
	cd $(CODK_FLASHPACK_DIR) && $(CODK_FLASHPACK_DIR)/flash_ble_dfu.sh $(BLE_IMAGE)

clean: clean-x86 clean-arc

clean-x86:
	-rm -rf $(OUT_DIR)

clean-arc:
	$(MAKE) -C $(ARC_PROJ_DIR) clean-all

debug-server-jlink:
	$(CODK_FLASHPACK_DIR)/bin/openocd -f $(CODK_FLASHPACK_DIR)/scripts/interface/ftdi/jlink.cfg -f $(CODK_FLASHPACK_DIR)/scripts/board/quark_se.cfg

debug-server-jtag:
	$(CODK_FLASHPACK_DIR)/bin/openocd -f $(CODK_FLASHPACK_DIR)/scripts/interface/ftdi/flyswatter2.cfg -f $(CODK_FLASHPACK_DIR)/scripts/board/quark_se.cfg

debug-server: debug-server-jtag

debug-x86:
	gdb $(OUT_X86_DIR)/zephyr.elf

debug-arc:
	$(CODK_ARC_DIR)/arc32/bin/arc-elf32-gdb $(ARC_PROJ_DIR)/arc.elf
