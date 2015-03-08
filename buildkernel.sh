#! /usr/bin/env bash
#
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

set -xe

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
# If not, set the default build dir (where the git repo is checked out)
# to $HOME
BuildEnv() {
  if [ -f /.dockerinit ]; then
    echo "Detected Docker"
    export BUILD_DIR="/app"
  else
    echo "Not running in Docker"
    export BUILD_DIR=$(pwd)
  fi
}


# --------------------SETUP--------------------

#
# Fingerprint of a trusted key the kernel is signed with.
# See http://www.kernel.org/signature.html
#     http://lwn.net/Articles/461647/
# ATTENTION: Make sure you really trust it!
TRUSTED_FINGERPRINT='ABAF 11C6 5A29 70B1 30AB  E3C4 79BE 3E43 0041 1886'

# Builds the latest upstream kernel version if not set.
if [ -z "$KERNEL_VERSION" ]; then
  KERNEL_VERSION=$(curl --silent https://www.kernel.org/finger_banner | awk '{print $11}'| head -2|tail -1)
fi

# Default string that is appended to the version if not set. For restrictions see the --append-to-version option of make-kpg.
VERSION_POSTFIX=${VERSION_POSTFIX-"-ci"}
PACKAGE_NAME="linux-image-$KERNEL_VERSION-$VERSION_POSTFIX.deb"

# Default URL where the archive and sources are located if not set.
SOURCE_URL_BASE=${SOURCE_URL_BASE-"https://kernel.org/pub/linux/kernel/v3.x"}

# Server used to get the trusted key from.
KEYSERVER=hkp://pool.sks-keyservers.net

# Set to yes if you want to build only the modules that are currently
# loaded Speeds up the build. But modules that are not currently
# loaded will be missing!  Only usefull if you really have to speed up
# the build time and the kernel is intended for the running system and
# the hardware is not expected to change.
BUILD_ONLY_LOADED_MODULES=no

function InstallPreqs()
{
  echo "You need the following packages installed fakeroot make build-essential kernel-package for this script to work"
}

# --------------DOWNLOAD------------------

# Remove spaces from the fingerprint to get a "long key ID" (see gpg manpage)
TRUSTEDLONGID=`echo $TRUSTED_FINGERPRINT |  sed "s/ //g"`

# Directory that is used by this script to store the trusted GPG-Key (not your personal GPG directory!)
export GNUPGHOME=./kernelkey

# Downloads the trusted key from a keyserver. Uses the trusted fingerprint to find the key.
function RecvKey()
{
  echo "Receiving key $TRUSTED_FINGERPRINT from the keyserver..."
  [ ! -d $GNUPGHOME ] || rm -rf $GNUPGHOME # makes sure no stale keys are hanging around
  mkdir $GNUPGHOME
  chmod og-rwx $GNUPGHOME
  gpg --keyserver $KEYSERVER --recv-keys $TRUSTEDLONGID
}

# Downloads the sources and their signature file.
function DownloadSources()
{
  DownloadManager $SOURCE_URL_BASE/linux-$KERNEL_VERSION.tar.xz
  DownloadManager $SOURCE_URL_BASE/linux-$KERNEL_VERSION.tar.sign
}

# Verifies the downloaded sources are signed with the trusted key and extracts them.
function VerifyExtract()
{
  echo "Extracting downloaded sources to tar..."
  [ -f linux-$KERNEL_VERSION.tar ] || unxz --keep linux-$KERNEL_VERSION.tar.xz

  # Commented out as often fails for no reason - would be nice to have though
  #echo "Verifying tar is signed with the trusted key..."
  #gpg -v --trusted-key 0x${TRUSTEDLONGID:24} --verify linux-$KERNEL_VERSION.tar.sign

  [ ! -d linux-$KERNEL_VERSION ] || rm -rf linux-$KERNEL_VERSION

  echo "Extracting tar..."
  tar -xf linux-$KERNEL_VERSION.tar
  rm linux-$KERNEL_VERSION.tar
}

# --------------CONFIG------------------

# Copies the configuration of the running kernel and applies defaults to all settings that are new in the upstream version.
function SetCurrentConfig()
{
  pushd ./linux-$KERNEL_VERSION

  # Copy settings of the currently running kernel
  cp $BUILD_DIR/kernel_config ./.config

  # Debuginfo is only needed if you plan to use binary object tools like crash, kgdb, and SystemTap on the kernel.
  scripts/config --disable DEBUG_INFO

  # Use the copied configuration and apply defaults to all new settings
  yes "" | make oldconfig

  if [ yes == $BUILD_ONLY_LOADED_MODULES ]
  then
    echo "Disabling modules that are not loaded by the running system..."
    make localmodconfig
  fi

  popd
}

# --------------BUILD------------------

function Build()
{
  pushd ./linux-$KERNEL_VERSION

  # See the following links for more information:
  # http://www.debian.org/doc/manuals/debian-faq/ch-kernel.en.html
  # http://www.debian.org/releases/stable/amd64/ch08s06.html.en
  echo "Now building the kernel, this will take a while..."
  time fakeroot make-kpkg --jobs `getconf _NPROCESSORS_ONLN` --append-to-version "$VERSION_POSTFIX" --initrd kernel_image
  mv ../linux-image*.deb ../$PACKAGE_NAME
  popd

  echo "Congratulations! You just build a linux kernel."
  echo "Use the following command to install it: dpkg -i $PACKAGE_NAME"
}

# Generates MD5sum of package
function Sum()
{
  pwd
  pushd ./linux-$KERNEL_VERSION
  md5sum $PACKAGE_NAME
  popd
}

# --------------EXPORT------------------

# Copies the package to the apt repo and imports it remotely with reprepro
function Push()
{
  pwd
  pushd ./linux-$KERNEL_VERSION

  scp $PACKAGE_NAME ci@aptproxy:/var/tmp
  ssh ci@aptproxy reprepro -A all -Vb /var/vhost/mycoolaptmirror.com/html /var/tmp/$PACKAGE_NAME
  popd

  echo "Image pushed to int-proxy and imported to reprepro"
}

# Pushes the package to packagecloud.io
function PackageCloud()
{
  pwd
  pushd ./linux-$KERNEL_VERSION
  # Remove the package if it already exists with the same name
  package_cloud yank mrmondo/debian-kernel/debian/jessie $PACKAGE_NAME || true
  package_cloud push mrmondo/debian-kernel/debian/jessie $PACKAGE_NAME && echo "Package uploaded to https://packagecloud.io/mrmondo/debian-kernel?filter=debs"
  popd
}

# --------------RUN------------------

# Run all function
CheckFreeSpace
BuildEnv
InstallPreqs
RecvKey
DownloadSources
VerifyExtract
SetCurrentConfig
Build

if [ "$PACKAGECLOUD" = "true" ]; then
  PackageCloud;
fi
