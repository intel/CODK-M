#!/bin/bash -e
Z_VER="$1"
ZSDK_VER="$2"
Z_PATH=$(readlink -m "$(pwd)/../zephyr")
ZSDK_FILE="zephyr-sdk-${ZSDK_VER}-i686-setup.run"
ZSDK_PATH=$(readlink -m "$(pwd)/../zephyr-sdk")

if [ -d ${Z_PATH} ]; then
    echo "Zephyr source already exists. Skipping installation."
else
    echo "Downloading Zephyr"
    #curl -sL http://bit.ly/1Y6G8d2 | tar xz
    curl -sL https://github.com/01org/zephyr/archive/codk-m.tar.gz | tar xz
    echo "Installing Zephyr to ${Z_PATH}"
    #mv zephyr-v${Z_VER} ${Z_PATH}
    mv zephyr-codk-m ${Z_PATH}
fi

if [ -d "${ZSDK_PATH}" ]; then
    echo "Zephyr SDK already exists. Skipping installation."
else
    if [ ! -f /tmp/${ZSDK_FILE} ] ; then
        echo "Downloading Zephyr SDK"
        curl -o /tmp/${ZSDK_FILE} -L https://nexus.zephyrproject.org/content/repositories/releases/org/zephyrproject/zephyr-sdk/${ZSDK_VER}-i686/${ZSDK_FILE}
        chmod 755 /tmp/${ZSDK_FILE}
    fi
    echo "Installing Zephyr SDK to ${ZSDK_PATH}"
    { echo "${ZSDK_PATH}"; } | /tmp/${ZSDK_FILE} --nox11
    echo "Setting options in ~/.zephyrrc"
    echo "export ZEPHYR_GCC_VARIANT=zephyr" > ~/.zephyrrc
    echo "export ZEPHYR_SDK_INSTALL_DIR=${ZSDK_PATH}" >> ~/.zephyrrc
fi

echo "Please run: source ${Z_PATH}/zephyr-env.sh"
