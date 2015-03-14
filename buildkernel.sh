#! /usr/bin/env bash
set -xe

# Much of this script was sourced from
# forums.debian.net/viewtopic.php?f=16&t=87006
# then *heavily* modified to support CI and Docker
#
# All output is stored in the current working directory. It is strongly
# recommended to run it in an empty directory.
#
# This script by default does the following:
#  - download the upstream sources of the linux kernel
#  - verify they are signed with a trusted GPG-key (currently disabled)
#  - use the configuration of your currently running kernel
#  - build a Debian-kernel package
#
# Each step is called as function at the end of the script. You can
# easily comment them out to skip them or to run manual steps (for
# example changing the kernel configuration with "make menuconfig").

# Please submit bugs and pull requests to
# https://github.com/sammcj/kernel-ci

# Optional variables that may be passed to this script:

# KERNEL_VERSION
# DEFAULT VALUE: Latest STABLE kernel version
#
# VERSION_POSTFIX
# For restrictions see the --append-to-version option of make-kpg.c
# DEFAULT VALUE: "-ci"

# TRUSTED_FINGERPRINT
# Fingerprint of a trusted key the kernel is signed with
# See http://www.kernel.org/signature.html
#     http://lwn.net/Articles/461647/
#     https://www.kernel.org/doc/wot/torvalds.html
# ATTENTION: Make sure you really trust it!
# DEFAULT VALUE: "ABAF 11C6 5A29 70B1 30AB E3C4 79BE 3E43 0041 1886"

# CHECK_KEY
# Enables fingerprint checking (recommended)
# DEFAULT VALUE: "true"

# SOURCE_URL_BASE
# Where the archive and sources are located
# DEFAULT VALUE: "https://kernel.org/pub/linux/kernel/v3.x"

# KEYSERVER
# Server used to get the trusted key from.
# DEFAULT VALUE: "hkp://keys.gnupg.net"

# BUILD_ONLY_LOADED_MODULES
# Set to yes if you want to build only the modules that are currently
# loaded Speeds up the build. But modules that are not currently
# loaded will be missing!  Only usefull if you really have to speed up
# the build time and the kernel is intended for the running system and
# the hardware is not expected to change.
# DEFAULT VALUE: "false"

### POST PROCESSING ###

# PACKAGECLOUD
# Enable pushing to reprepro upon successful build
# DEFAULT VALUE: "false"

# PACKAGE_CLOUD_URL
# Must be replaced if you wish to upload to packagecloud.io
# DEFAULT VALUE: "mrmondo/debian-kernel/debian/jessie"

# REPREPRO
# Enable pushing to reprepro upon successful build
# DEFAULT VALUE: "false"

# REREPRO_HOST
# The username and password to login to the reprepro host
# DEFAULT VALUE: "ci@aptproxy"

# REPREPO_URL
# The URL of the reprepro mirror
# DEFAULT VALUE: "var/vhost/mycoolaptmirror.com/html"

# -------------VARIABLES---------------

TRUSTED_FINGERPRINT='ABAF 11C6 5A29 70B1 30AB E3C4 79BE 3E43 0041 1886'
VERSION_POSTFIX=${VERSION_POSTFIX-"-ci"}
SOURCE_URL_BASE=${SOURCE_URL_BASE-"https://kernel.org/pub/linux/kernel/v3.x"}
KEYSERVER=hkp://keys.gnupg.net
BUILD_ONLY_LOADED_MODULES=${BUILD_ONLY_LOADED_MODULES-"no"}
PACKAGECLOUD=${PACKAGECLOUD-"true"}
REPREPRO=${REPREPRO-"false"}
PACKAGE_CLOUD_URL=${PACKAGE_CLOUD_URL-"mrmondo/debian-kernel/debian/jessie"}
REREPRO_HOST=${REREPRO_HOST-"ci@aptproxy"}
REPREPO_URL=${REPREPO_URL-"var/vhost/mycoolaptmirror.com/html"}

if [ -z "$KERNEL_VERSION" ]; then
  KERNEL_VERSION=$(curl --silent https://www.kernel.org/finger_banner | awk '{print $11}'| head -2|tail -1)
fi

# -------------PRE-FLIGHT---------------

# Check there is at least 500MB of free disk space
CheckFreeSpace() {
  if (($(df -m . | awk 'NR==2 {print $4}') < 500 )); then
    echo "Not enough free disk space, you need at least 500MB";
    exit 1;
  fi
}

echo "$(getconf _NPROCESSORS_ONLN) CPU cores detected"

# Use aria2 crather than wget if installed
DownloadManager() {
  if hash aria2c 2>/dev/null; then
    aria2c "$@";
  else
    wget "$@";
  fi
}

# Are we running in Docker?
# If not, set the default build dir (where the git repo is checked out) to $HOME
BuildEnv() {
  if [ -f /.dockerinit ]; then
    echo "Detected Docker"
    export BUILD_DIR="/app"
  else
    echo "Not running in Docker"
    export BUILD_DIR=$(pwd)
  fi
}

# --------------DOWNLOAD------------------

# Remove spaces from the fingerprint to get a "long key ID" (see gpg manpage)
TRUSTEDLONGID=$(echo "$TRUSTED_FINGERPRINT" |  sed "s/ //g")

# Directory that is used by this script to store the trusted GPG-Key (not your personal GPG directory!)
export GNUPGHOME=./kernelkey

# Downloads the trusted key from a keyserver. Uses the trusted fingerprint to find the key.
function RecvKey()
{
  echo "Receiving key $TRUSTED_FINGERPRINT from the keyserver..."
  [ ! -d "$GNUPGHOME" ] || rm -rf "$GNUPGHOME" # makes sure no stale keys are hanging around
  mkdir "$GNUPGHOME"
  chmod og-rwx "$GNUPGHOME"
  # gpg --keyserver "$KEYSERVER" --recv-keys "$TRUSTEDLONGID"
  gpg --keyserver "$KEYSERVER" --recv-keys 517D0F0E
}

# Downloads the sources and their signature file.
function DownloadSources()
{
  DownloadManager "$SOURCE_URL_BASE/linux-$KERNEL_VERSION".tar.xz
  DownloadManager "$SOURCE_URL_BASE/linux-$KERNEL_VERSION".tar.sign
}

# Verifies the downloaded sources are signed with the trusted key and extracts them.
function VerifyExtract()
{
  echo "Extracting downloaded sources to tar..."
  [ -f linux-"$KERNEL_VERSION".tar ] || unxz --keep linux-"$KERNEL_VERSION".tar.xz

  if [ "$CHECK_KEY" != "false" ]
  then

    echo "Verifying tar is signed with the trusted key..."
    gpg -v --trusted-key 517D0F0E --verify linux-"$KERNEL_VERSION".tar.sign

  fi

  [ ! -d linux-"$KERNEL_VERSION" ] || rm -rf linux-"$KERNEL_VERSION"

  echo "Extracting tar..."
  tar -xf linux-"$KERNEL_VERSION".tar
  rm linux-"$KERNEL_VERSION".tar
}

# --------------CONFIG------------------

# Copies the configuration of the running kernel and applies defaults to all settings that are new in the upstream version.
function SetCurrentConfig()
{
  pushd ./linux-"$KERNEL_VERSION"

  # Copy settings of the currently running kernel
  cp "$BUILD_DIR"/kernel_config ./.config

  # Debuginfo is only needed if you plan to use binary object tools like crash, kgdb, and SystemTap on the kernel.
  scripts/config --disable DEBUG_INFO

  # Use the copied configuration and apply defaults to all new settings
  yes "" | make oldconfig

  if [ "$BUILD_ONLY_LOADED_MODULES" = "true" ]
  then
    echo "Disabling modules that are not loaded by the running system..."
    make localmodconfig
  fi

  popd
}

# --------------BUILD------------------

function Build()
{
  pushd ./linux-"$KERNEL_VERSION"

  echo "Now building the kernel, this will take a while..."
  time fakeroot make-kpkg --jobs "$(getconf _NPROCESSORS_ONLN)" --append-to-version "$VERSION_POSTFIX" --initrd kernel_image

  popd

  PACKAGE_NAME="$(ls -m1 linux-image*.deb)"
  echo "Congratulations! You just build a linux kernel."
  echo "Use the following command to install it: dpkg -i $PACKAGE_NAME"
}

# Generates MD5sum of package
function Sum()
{
  pwd
  pushd ./linux-"$KERNEL_VERSION"
  md5sum "$PACKAGE_NAME"
  popd
}

# --------------EXPORT------------------

# Copies the package to the apt repo and imports it remotely with reprepro
function RepreproPush()
{
  pwd
  pushd ./linux-"$KERNEL_VERSION"

  scp "$PACKAGE_NAME" "$REREPRO_HOST":/var/tmp
  ssh "$REREPRO_HOST" reprepro -A all -Vb "$REPREPO_URL" /var/tmp/"$PACKAGE_NAME"
  popd

  echo "Image pushed to $REREPRO_HOST and imported to reprepro"
}

# Pushes the package to packagecloud.io
function PackageCloud()
{
  pwd && ls -l

  package_cloud yank $PACKAGE_CLOUD_URL $PACKAGE_NAME || true
  package_cloud push $PACKAGE_CLOUD_URL $PACKAGE_NAME

}

# --------------RUN------------------

# Run all function
CheckFreeSpace
BuildEnv
RecvKey
DownloadSources
VerifyExtract
SetCurrentConfig
Build

if [ "$REPREPRO" = "true" ]; then
  RepreproPush;
fi

if [ "$PACKAGECLOUD" = "true" ]; then
  PackageCloud;
fi
