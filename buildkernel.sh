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

# APT_UPDATE
# Performs an apt-get update and upgrade before build
# DEFAULT VALUE: "true"

# KERNEL_VERSION
# DEFAULT VALUE: Latest STABLE kernel version
#
# VERSION_POSTFIX
# For restrictions see the --append-to-version option of make-kpg.c
# DEFAULT VALUE: "-ci"

# SOURCE_URL_BASE
# Where the archive and sources are located
# DEFAULT VALUE: "https://kernel.org/pub/linux/kernel/v3.x"

# TRUSTED_FINGERPRINT
# Fingerprint of a trusted key the kernel is signed with
# See http://www.kernel.org/signature.html
#     http://lwn.net/Articles/461647/
#     https://www.kernel.org/doc/wot/torvalds.html
# ATTENTION: Make sure you really trust it!
# DEFAULT VALUE: "C75D C40A 11D7 AF88 9981  ED5B C86B A06A 517D 0F0E"

# CHECK_KEY
# Enables fingerprint checking (recommended)
# DEFAULT VALUE: "true"

# KEYSERVER
# Server used to get the trusted key from.
# DEFAULT VALUE: "x-hkp://pool.sks-keyservers.net"

# KERNEL_ORG_KEY
# Currently using Greg Kroah-Hartman's public key
# DEFAULT VALUE: "6092693E"

# STOCK_CONFIG
# Currently using Debian Jessie 3.16 config
# DEFAULT VALUE: "config-3.16.0-0.bpo.4-amd64"

# BUILD_ONLY_LOADED_MODULES
# Set to yes if you want to build only the modules that are currently
# loaded Speeds up the build. But modules that are not currently
# loaded will be missing!  Only usefull if you really have to speed up
# the build time and the kernel is intended for the running system and
# the hardware is not expected to change.
# DEFAULT VALUE: "false"

### GRSECURITY ###

# GRSEC
# Enable GRSecurity Patching
# DEFAULT VALUE: "false"

# GRSEC_RSS
# Source of GRSecurity patch RSS feed
# DEFAULT VALUE: "https://grsecurity.net/testing_rss.php"

# GRSEC_KEY
# Currently using The PaX Team <pageexec at freemail dot hu> public key
# See http://sks.pkqs.net/pks/lookup?op=vindex&fingerprint=on&search=0x44D1C0F82525FE49
# DEFAULT VALUE: "2525FE49"

# GRSEC_TRUSTED_FINGERPRINT
# Fingerprint of a trusted key the GRSecurity patch is signed with
# See https://grsecurity.net/download.php
# ATTENTION: Make sure you really trust it!
# DEFAULT VALUE: "DE94 52CE 46F4 2094 907F 108B 44D1 C0F8 2525 FE49"

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

# REPREPRO_HOST
# The username and password to login to the reprepro host
# DEFAULT VALUE: "ci@aptproxy"

# REPREPO_URL
# The URL of the reprepro mirror
# DEFAULT VALUE: "var/vhost/mycoolaptmirror.com/html"

# -------------VARIABLES---------------

APT_UPDATE=${APT_UPDATE:-"true"}
TRUSTED_FINGERPRINT=${TRUSTED_FINGERPRINT:-"C75D C40A 11D7 AF88 9981  ED5B C86B A06A 517D 0F0E"}
VERSION_POSTFIX=${VERSION_POSTFIX:-"-ci"}
SOURCE_URL_BASE=${SOURCE_URL_BASE:-"https://kernel.org/pub/linux/kernel/v3.x"}
KEYSERVER=${KEYSERVER:-"x-hkp://pool.sks-keyservers.net"}
KERNEL_ORG_KEY=${KERNEL_ORG_KEY:-"6092693E"}
BUILD_ONLY_LOADED_MODULES=${BUILD_ONLY_LOADED_MODULES:-"false"}
PACKAGECLOUD=${PACKAGECLOUD:-"false"}
REPREPRO=${REPREPRO:-"false"}
PACKAGE_CLOUD_URL=${PACKAGE_CLOUD_URL:-"mrmondo/debian-kernel/debian/jessie"}
REPREPRO_HOST=${REPREPRO_HOST:-"ci@aptproxy"}
REPREPO_URL=${REPREPO_URL:-"var/vhost/mycoolaptmirror.com/html"}
GRSEC=${GRSEC:-"false"}
GRSEC_RSS=${GRSEC_RSS:-"https://grsecurity.net/testing_rss.php"}
GRSEC_TRUSTED_FINGERPRINT=${GRSEC_TRUSTED_FINGERPRINT:="DE94 52CE 46F4 2094 907F 108B 44D1 C0F8 2525 FE49"}
GRSEC_KEY=${GRSEC_KEY:="2525FE49"}
GCC_VERSION="$(gcc -dumpversion|awk -F "." '{print $1"."$2}')"
STOCK_CONFIG=${STOCK_CONFIG:="config-3.16.0-0.bpo.4-amd64"}

if [ "$GRSEC" = "true" ]; then
  # Get the latest grsec patch
  LATEST_GRSEC_PATCH="$(curl "${GRSEC_RSS}"|egrep -o 'https[^ ]*.patch'|sort|uniq|head -1)"
  LATEST_GRSEC_KERNEL_VERSION="$(echo "$LATEST_GRSEC_PATCH"|cut -f 3 -d -;)"
  KERNEL_VERSION="$LATEST_GRSEC_KERNEL_VERSION"
  GRSEC_TRUSTEDLONGID=$(echo "$GRSEC_TRUSTED_FINGERPRINT" |  sed "s/ //g")
else
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

# Use aria2 crather than curl if installed
DownloadManager() {
  if hash aria2c 2>/dev/null; then
    aria2c "$@";
  else
    curl -O "$@";
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
    apt-get -y install "gcc-$GCC_VERSION-plugin-dev" coreutils fakeroot build-essential kernel-package wget xz-utils gnupg bc devscripts apt-utils initramfs-tools time aria2
    apt-get clean
  fi
}

if [ "$APT_UPDATE" = "true" ]; then
  echo "Performing apt-get update..."
  apt-get -qq update
  echo "Performing apt-get upgrade..."
  apt-get -qq upgrade
fi

mkdir -p kpatch

# --------------DOWNLOAD------------------

# Remove spaces from the fingerprint to get a "long key ID" (see gpg manpage)
TRUSTEDLONGID=$(echo "$TRUSTED_FINGERPRINT" |  sed "s/ //g")

# Directory that is used by this script to store the trusted GPG-Key (not your personal GPG directory!)
export GNUPGHOME="$BUILD_DIR/kernelkey"

# Downloads the trusted key from a keyserver. Uses the trusted fingerprint to find the key.
function RecvKey()
{
  echo "Receiving key $TRUSTED_FINGERPRINT from the keyserver..."
  [ ! -d "$GNUPGHOME" ] || rm -rf "$GNUPGHOME" # makes sure no stale keys are hanging around
  mkdir "$GNUPGHOME"
  chmod og-rwx "$GNUPGHOME"

  # Sometimes fetching the GPG key may fail, wait one second and try again
  KEY_MAX_TRIES=5
  COUNT=0
  while [  $COUNT -lt $KEY_MAX_TRIES ]; do
    gpg --keyserver "$KEYSERVER" --recv-keys "$KERNEL_ORG_KEY"
    if [ $? -eq 1 ];then
      sleep 1
      let COUNT=COUNT+1
    else
      break
    fi
  done
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
    gpg -v --trusted-key "0x${TRUSTEDLONGID:24}" --verify linux-"$KERNEL_VERSION".tar.sign

  fi

  [ ! -d linux-"$KERNEL_VERSION" ] || rm -rf linux-"$KERNEL_VERSION"

  echo "Extracting tar..."
  tar -xf linux-"$KERNEL_VERSION".tar
  rm linux-"$KERNEL_VERSION".tar
}

# --------------CONFIG------------------

#Create the kernel config including patches

function PatchKernelConfig()
{
  pushd ./linux-"$KERNEL_VERSION"
  mv ../kernel_config.sh .

  # Copy config from wheezy-backports as Jessie is frozen
  rm -f ".config"
  mv ../"$STOCK_CONFIG" .config
  # curl -o ".config" "http://anonscm.debian.org/viewvc/kernel/dists/wheezy-backports/linux/debian/config/config?view=co"
  ./kernel_config.sh

  popd
}


# Copies the configuration of the running kernel and applies defaults to all settings that are new in the upstream version.
function SetCurrentConfig()
{
  pushd ./linux-"$KERNEL_VERSION"

  # Use the copied configuration and apply defaults to all new settings
  yes "" | make oldconfig

  if [ "$BUILD_ONLY_LOADED_MODULES" = "true" ]
  then
    echo "Disabling modules that are not loaded by the running system..."
    make localmodconfig
  fi

  popd
}

# --------------PATCH------------------

function InstallGrsecurity()
{
  pushd ./linux-"$KERNEL_VERSION"

  echo "Patch located at $LATEST_GRSEC_PATCH, downloading"
  curl -o ../kpatch/grsecurity.patch "$LATEST_GRSEC_PATCH"
  curl -o ../kpatch/grsecurity.patch.sig "$LATEST_GRSEC_PATCH.sig"

  gpg --keyserver "$KEYSERVER" --recv-keys "$GRSEC_KEY"

  echo "Verifying patch is signed with the trusted key..."
  gpg -v --trusted-key "0x${GRSEC_TRUSTEDLONGID:24}" --verify ../kpatch/grsecurity.patch.sig

  echo "Patching kernel for GRSecurity..."
  patch -p1 < ../kpatch/grsecurity.patch
  echo "Patch done"

  popd
}

# --------------BUILD------------------

function Build()
{
  pushd ./linux-"$KERNEL_VERSION"

  echo "Now building the kernel, this will take a while..."
  time fakeroot make-kpkg --jobs "$(getconf _NPROCESSORS_ONLN)" --append-to-version "$VERSION_POSTFIX" --initrd kernel_image
  time fakeroot make-kpkg --jobs "$(getconf _NPROCESSORS_ONLN)" --append-to-version "$VERSION_POSTFIX" --initrd kernel_headers
  popd

  PACKAGE_NAME="$(ls -m1 linux-image*.deb)"
  HEADERS_PACKAGE_NAME="$(ls -m1 linux-headers*.deb)"
  echo "Congratulations! You just build a linux kernel."
  echo "Use the following command to install it: dpkg -i $PACKAGE_NAME $HEADERS_PACKAGE_NAME"
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

  scp "$PACKAGE_NAME $HEADERS_PACKAGE_NAME" "$REPREPRO_HOST":/var/tmp
  ssh "$REPREPRO_HOST" reprepro -A all -Vb "$REPREPO_URL" /var/tmp/"$PACKAGE_NAME"
  popd

  echo "Image pushed to $REPREPRO_HOST and imported to reprepro"
}

# Pushes the package to packagecloud.io
function PackageCloud()
{
  pwd && ls -l

  package_cloud yank "$PACKAGE_CLOUD_URL" "$PACKAGE_NAME" || true
  package_cloud push "$PACKAGE_CLOUD_URL" "$PACKAGE_NAME"

  package_cloud yank "$PACKAGE_CLOUD_URL" "$HEADERS_PACKAGE_NAME" || true
  package_cloud push "$PACKAGE_CLOUD_URL" "$HEADERS_PACKAGE_NAME"

}

# --------------RUN------------------

# Run all function
CheckFreeSpace
BuildEnv
RecvKey
DownloadSources
VerifyExtract

if [ "$GRSEC" = "true" ]; then
  InstallGrsecurity;
fi

PatchKernelConfig
SetCurrentConfig
Build

if [ "$REPREPRO" = "true" ]; then
  RepreproPush;
fi

if [ "$PACKAGECLOUD" = "true" ]; then
  PackageCloud;
fi
