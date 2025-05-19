#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

USER_NAME="${USER_NAME:-"${_REMOTE_USER:-"automatic"}"}"

set -e

# Setup STDERR.
err() {
    echo "(!) $*" >&2
}

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Determine the appropriate non-root user
if [ "${USER_NAME}" = "auto" ] || [ "${USER_NAME}" = "automatic" ]; then
    USER_NAME="container_user"
elif [ "${USER_NAME}" = "none" ] || [ "${USER_NAME}" = "" ]; then
    USER_NAME=root
else
    USER_NAME=${USER_NAME}
fi

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

#
# Setup build tools
#
check_packages build-essential
check_packages pkg-config
check_packages meson ninja-build
check_packages gettext intltool
check_packages libfontconfig1-dev
check_packages libass-dev
check_packages libboost-chrono-dev libboost-locale-dev libboost-regex-dev libboost-system-dev libboost-thread-dev
check_packages zlib1g-dev
check_packages wx3.2-headers libwxgtk3.2-dev
check_packages icu-devtools libicu-dev
check_packages libpulse-dev
check_packages libasound2-dev
check_packages libopenal-dev
check_packages libffms2-dev
check_packages libfftw3-dev
check_packages libhunspell-dev
check_packages libuchardet-dev
check_packages libcurl4-gnutls-dev
check_packages libgl1-mesa-dev
check_packages libgtest-dev
check_packages libgmock-dev

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
