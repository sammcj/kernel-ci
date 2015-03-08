#!/bin/bash -e
#
# Author: Sam McLeod - github.com/sammcj
#
# 1. Checks out a git repo
# 2. Checks the latest stable kernel from kernel.org
# 3. If there are any changes they will be added, commited and pushed
# 4. This will trigger a Travis-CI run that will in turn build a Debian package of the kernel
# 5. And upload the successful build to packagecloud.io

git reset --hard HEAD
git pull

curl --silent https://www.kernel.org/finger_banner | awk '/ stable /{print $(NF)}' | tail -1 > stable_kernel_version

git add stable_kernel_version
git commit -m "Bumping kernel to version $(cat stable_kernel_version)" --author="Kernel Watch <kernelwatch@auto.smcleod.net>" || true
git push
