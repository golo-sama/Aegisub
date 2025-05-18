#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

PS_VERSION="${POWERSHELL_VERSION:-"7.5.1"}"
GROUP_NAME="${GROUP_NAME:-"container_group"}"
GROUP_ID="${GROUP_ID:-"1001"}"
USER_NAME="${USER_NAME:-"${_REMOTE_USER:-"automatic"}"}"
USER_ID="${USER_ID:-"1001"}"

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
# Install PowerShell
# https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu
#
# Install dependencies
check_packages wget ca-certificates

# Download the PowerShell package file
wget --progress=dot:giga https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/powershell_${PS_VERSION}-1.deb_amd64.deb

###################################
# Install the PowerShell package and ignore errors to allow dependency fixes with apt afterwards
dpkg -i powershell_${PS_VERSION}-1.deb_amd64.deb || true

# Resolve missing dependencies and finish the install (if necessary)
apt install -f -y --no-install-recommends

# Delete the downloaded package file
rm powershell_${PS_VERSION}-1.deb_amd64.deb

#
# Setup git with ssh
#
check_packages git openssh-client

#
# Setup user and group
#
# Delete default ubuntu user to allow UID 1000 for new user
userdel ubuntu

# Add new user and group
if [ "${USER_NAME}" != "root" ]; then
    groupadd ${GROUP_NAME} --gid ${GROUP_ID}
    useradd ${USER_NAME} --uid ${USER_ID} --gid ${GROUP_ID} --create-home --shell "/usr/bin/pwsh"
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
