![kernel_300](https://cloud.githubusercontent.com/assets/862951/6546050/53636040-c5f7-11e4-94d4-5e2dbfb8a27c.png)

[![Build Status](https://img.shields.io/travis/sammcj/kernel-ci.svg?style=flat-square)](https://travis-ci.org/sammcj/kernel-ci) [![Issues](https://img.shields.io/github/issues/sammcj/kernel-ci.svg?style=flat-square)](https://github.com/sammcj/kernel-ci/issues)

[![Issue Count](https://codeclimate.com/github/sammcj/kernel-ci/badges/issue_count.svg)](https://codeclimate.com/github/sammcj/kernel-ci)

### Linux Kernel CI for Debian

* Uploads publicly accessable Debian Kernel Packages to [packagecloud.io](https://packagecloud.io/mrmondo/debian-kernel?filter=debs)
* Includes Kernel Watcher that detects new stable kernel releases and triggers builds.
* Supports patching the Kernel with GRSecurity
* Tested with Gitlab-CI and Travis-CI but should work on any CI system.
* Runs in an isolated and disposble docker container.
* No root access required when building with Docker.
* Both the build and the kernels Work with Debian Wheezy (7) and Jessie (8).
* Supports uploading built packages to a remote server and adding them to [reprepro](https://wiki.debian.org/SettingUpSignedAptRepositoryWithReprepro)
* Allows advanced kernel configuration and options

---

<!-- MarkdownTOC -->

- [Usage](#usage)
- [Public CI Builds](#public-ci-builds)
- [Optional Configuration](#optional-configuration)
- [TODO:](#todo)
- [Example Output](#example-output)

<!-- /MarkdownTOC -->

---

## Usage
### Docker
```bash
make ci
```
After a successfully building the kernel package, the kernel will be copied to /mnt/storage on the host.
### Build Kernel Deb Without Docker
```bash
EXPORT BUILD_DIR=/home/ci #Repo location - Defaults to $HOME
sudo sed -i -e 's/^Defaults\tsecure_path.*$//' /etc/sudoers
sudo -E buildkernel.sh
```

## Public CI Builds
Successful builds from this project get uploaded to [PackageCloud.io](https://packagecloud.io/mrmondo/debian-kernel?filter=debs)

You may add the repository for them by running: `curl https://packagecloud.io/install/repositories/mrmondo/debian-kernel/script.deb | sudo bash`

## Optional Configuration
The following optional environment variables can be configured as required

* Advanced kernel options / configuration can be configured in [kernel_config.sh](https://github.com/sammcj/kernel-ci/blob/master/kernel_config.sh)

For example:

#### APT_UPDATE
Perform an apt-get update and upgrade prior to building

Default Value: `false`

#### KERNEL_VERSION
Default Value: Latest STABLE kernel version

#### VERSION_POSTFIX
For restrictions see the --append-to-version option of make-kpg.c

Default Value: `-ci`

#### TRUSTED_FINGERPRINT
Fingerprint of a trusted key the kernel is signed with
See http://www.kernel.org/signature.html
    http://lwn.net/Articles/461647/

ATTENTION: Make sure you really trust it!

Default Value: `ABAF 11C6 5A29 70B1 30AB  E3C4 79BE 3E43 0041 1886`

#### SOURCE\_URL_BASE
Where the archive and sources are located

Default Value: `https://kernel.org/pub/linux/kernel/v4.x`

#### KEYSERVER
Server used to get the trusted key from.

Default Value: `hkp://pool.sks-keyservers.net`

etc...

#### STOCK_CONFIG
The kernel config to use for the build

_Note_ if using a modern config such as the 4.5.5 config's provided in this repo, you must be using a modern very of GCC that supports `fstack-protector-strong`, otherwise you will get this error:

```bash
Makefile:667: Cannot use CONFIG_CC_STACKPROTECTOR_STRONG: -fstack-protector-strong not supported by compiler
```

### Post Processing Options

#### PACKAGECLOUD
Enable pushing to reprepro upon successful build

Default Value: `false`

#### PACKAGE\_CLOUD_URL
Must be replaced if you wish to upload to packagecloud.io

Default Value: `mrmondo/debian-kernel/debian/jessie`

#### REPREPRO
Enable pushing to reprepro upon successful build

Default Value: `false`

#### REPREPRO_HOST
The username and password to login to the reprepro host

Default Value: `ci@aptproxy`

#### REPREPO_URL
The URL of the reprepro mirror

Default Value: `var/vhost/mycoolaptmirror.com/html`

## TODO:
* See [issues](https://github.com/sammcj/kernel-ci/issues)

## Example Output
```bash
cd /home/gitlab_ci_runner/gitlab-ci-runner/tmp/builds/project-27 && git reset --hard && git clean -fdx && git remote set-url origin https://gitlab-ci-token:blablabla@gitlab.yourcompany.com/systems/kernel.git && git fetch origin
HEAD is now at 9faa7a2 initramfs-tools
From https://gitlab.yourcompany.com/systems/kernel
   9faa7a2..4ec20fd  master     -> origin/master
cd /home/gitlab_ci_runner/gitlab-ci-runner/tmp/builds/project-27 && git reset --hard && git checkout 4ec20fdb1f677a2f51b6e37a92a1fff61434ab52
HEAD is now at 9faa7a2 initramfs-tools
Previous HEAD position was 9faa7a2... initramfs-tools
HEAD is now at 4ec20fd... cleanup
make ci
RUNNING ON int-ci-02
RUNNING AS gitlab_ci_runner
make build
make[1]: Entering directory `/home/gitlab_ci_runner/gitlab-ci-runner/tmp/builds/project-27'
docker build -t contyard.yourcompany.com/linux-kernel: .
Sending build context to Docker daemon 519.2 kB

Sending build context to Docker daemon
Step 0 : FROM contyard.yourcompany.com/wheezy
 ---> 38ce0497b79a
Step 1 : MAINTAINER systems
 ---> Using cache
 ---> 5181ce4604b0
Step 2 : ENV DEBIAN_FRONTEND noninteractive
 ---> Using cache
 ---> 3b741575bd57
Step 3 : RUN apt-get -qq update && apt-get -qq install fakeroot build-essential kernel-package wget xz-utils gnupg bc devscripts apt-utils initramfs-tools && apt-get clean
 ---> Using cache
 ---> e9a92e2943ad
Step 4 : RUN mkdir -p /mnt/storage
 ---> Running in 4605ab2fa2bf
 ---> 902c01ee6f86
Removing intermediate container 4605ab2fa2bf
Step 5 : WORKDIR /app
 ---> Running in 5b9d3ab98da3
 ---> e86e27a7d592
Removing intermediate container 5b9d3ab98da3
Step 6 : ADD buildkernel.sh /app/buildkernel.sh
 ---> 1261802d8c83
Removing intermediate container 8c10c00de0ee
Step 7 : ADD kernel_config /app/.config
 ---> 5a8446b33beb
Removing intermediate container 5b872e547af5
Step 8 : RUN chmod +x buildkernel.sh && ./buildkernel.sh
 ---> Running in df3c7c8e464d
You need the following packages installed fakeroot make build-essential kernel-package for this script to work
Recieving key ABAF 11C6 5A29 70B1 30AB  E3C4 79BE 3E43 0041 1886 from the keyserver...
gpg: keyring `./kernelkey/secring.gpg' created
gpg: keyring `./kernelkey/pubring.gpg' created
gpg: requesting key 00411886 from hkp server pool.sks-keyservers.net
gpg: ./kernelkey/trustdb.gpg: trustdb created
gpg: key 00411886: public key "Linus Torvalds <torvalds@linux-foundation.org>" imported
gpg: no ultimately trusted keys found
gpg: Total number processed: 1
gpg:               imported: 1  (RSA: 1)
--2015-01-21 02:32:50--  http://mirror.aarnet.edu.au/pub/ftp.kernel.org/linux/kernel/v3.x/linux-3.18.3.tar.xz
Resolving mirror.aarnet.edu.au (mirror.aarnet.edu.au)... 202.158.214.106, 2001:388:30bc:cafe::beef
Connecting to mirror.aarnet.edu.au (mirror.aarnet.edu.au)|202.158.214.106|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 80944856 (77M) [application/x-xz]
Saving to: `linux-3.18.3.tar.xz'

     0K .......... .......... .......... .......... ..........  0%  128K 10m16s
    50K .......... .......... .......... .......... ..........  0%  320K 7m11s
   100K .......... .......... .......... .......... ..........  0%  638K 5m29s
   150K .......... .......... .......... .......... ..........  0%  639K 4m37s
   200K .......... .......... .......... .......... ..........  0%  641K 4m6s
   250K .......... .......... .......... .......... ..........  0% 42.8M 3m25s
   300K .......... .......... .......... .......... ..........  0%  641K 3m13s
```
...
```bash
 78950K .......... .......... .......... .......... .......... 99%  641K 0s
 79000K .......... .......... .......... .......... .......   100%  614K=1m41s

2015-01-21 02:34:31 (782 KB/s) - `linux-3.18.3.tar.xz' saved [80944856/80944856]

--2015-01-21 02:34:31--  http://mirror.aarnet.edu.au/pub/ftp.kernel.org/linux/kernel/v3.x/linux-3.18.3.tar.sign
Resolving mirror.aarnet.edu.au (mirror.aarnet.edu.au)... 202.158.214.106, 2001:388:30bc:cafe::beef
Connecting to mirror.aarnet.edu.au (mirror.aarnet.edu.au)|202.158.214.106|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 819 [application/x-tar]
Saving to: `linux-3.18.3.tar.sign'

     0K                                                       100% 59.6M=0s

2015-01-21 02:34:31 (59.6 MB/s) - `linux-3.18.3.tar.sign' saved [819/819]

Extracting downloaded sources to tar...
Extracting tar...
/app/linux-3.18.3 /app
  HOSTCC  scripts/basic/fixdep
  HOSTCC  scripts/kconfig/conf.o
  SHIPPED scripts/kconfig/zconf.tab.c
  SHIPPED scripts/kconfig/zconf.lex.c
  SHIPPED scripts/kconfig/zconf.hash.c
  HOSTCC  scripts/kconfig/zconf.tab.o
  HOSTLD  scripts/kconfig/conf
scripts/kconfig/conf --oldconfig Kconfig
#
# configuration written to .config
#
/app
/app/linux-3.18.3 /app
exec make kpkg_version=12.036+nmu3 -f /usr/share/kernel-package/ruleset/minimal.mk debian APPEND_TO_VERSION=-ix  INITRD=YES 
====== making target debian/stamp/conf/minimal_debian [new prereqs: ]======
This is kernel package version 12.036+nmu3.
test -d debian             || mkdir debian
test ! -e stamp-building || rm -f stamp-building
install -p -m 755 /usr/share/kernel-package/rules debian/rules
for file in ChangeLog  Control  Control.bin86 config templates.in rules; do                                      \
            cp -f  /usr/share/kernel-package/$file ./debian/;                               \
        done
for dir  in Config docs examples ruleset scripts pkg po;  do                                      \
          cp -af /usr/share/kernel-package/$dir  ./debian/;                                 \
        done
test -f debian/control || sed         -e 's/=V/3.18.3-ix/g'  \
                -e 's/=D/3.18.3-ix-10.00.Custom/g'         -e 's/=A/amd64/g'  \
    -e 's/=SA//g'  \
    -e 's/=I//g'            \
    -e 's/=CV/3.18/g'         \
    -e 's/=M/Unknown Kernel Package Maintainer <unknown@unconfigured.in.etc.kernel-pkg.conf>/g'         \
    -e 's/=ST/linux/g'      -e 's/=B/x86_64/g'    \
                  /usr/share/kernel-package/Control > debian/control
test -f debian/changelog ||  sed -e 's/=V/3.18.3-ix/g'       \
            -e 's/=D/3.18.3-ix-10.00.Custom/g'        -e 's/=A/amd64/g'       \
            -e 's/=ST/linux/g'     -e 's/=B/x86_64/g'         \
            -e 's/=M/Unknown Kernel Package Maintainer <unknown@unconfigured.in.etc.kernel-pkg.conf>/g'                            \
             /usr/share/kernel-package/changelog > debian/changelog
chmod 0644 debian/control debian/changelog
test -d ./debian/stamp || mkdir debian/stamp 
make -f debian/rules debian/stamp/conf/kernel-conf
make[1]: Entering directory `/app/linux-3.18.3'
====== making target debian/stamp/conf/kernel-conf [new prereqs: ]======
make EXTRAVERSION=-ix   ARCH=x86_64 \
                    oldconfig;
make[2]: Entering directory `/app/linux-3.18.3'
scripts/kconfig/conf --oldconfig Kconfig
#
# configuration written to .config
#
make[2]: Leaving directory `/app/linux-3.18.3'
make EXTRAVERSION=-ix   ARCH=x86_64 prepare
make[2]: Entering directory `/app/linux-3.18.3'
scripts/kconfig/conf --silentoldconfig Kconfig
make[2]: Leaving directory `/app/linux-3.18.3'
make[2]: Entering directory `/app/linux-3.18.3'
  SYSTBL  arch/x86/syscalls/../include/generated/asm/syscalls_32.h
  SYSHDR  arch/x86/syscalls/../include/generated/asm/unistd_32_ia32.h
  SYSHDR  arch/x86/syscalls/../include/generated/asm/unistd_64_x32.h
  SYSTBL  arch/x86/syscalls/../include/generated/asm/syscalls_64.h
  SYSHDR  arch/x86/syscalls/../include/generated/uapi/asm/unistd_32.h
  SYSHDR  arch/x86/syscalls/../include/generated/uapi/asm/unistd_64.h
  SYSHDR  arch/x86/syscalls/../include/generated/uapi/asm/unistd_x32.h
  HOSTCC  arch/x86/tools/relocs_32.o
  HOSTCC  arch/x86/tools/relocs_64.o
  HOSTCC  arch/x86/tools/relocs_common.o
  HOSTLD  arch/x86/tools/relocs
  CHK     include/config/kernel.release
  UPD     include/config/kernel.release
  WRAP    arch/x86/include/generated/asm/clkdev.h
  WRAP    arch/x86/include/generated/asm/cputime.h
  WRAP    arch/x86/include/generated/asm/dma-contiguous.h
  WRAP    arch/x86/include/generated/asm/early_ioremap.h
  WRAP    arch/x86/include/generated/asm/mcs_spinlock.h
  WRAP    arch/x86/include/generated/asm/scatterlist.h
  CHK     include/generated/uapi/linux/version.h
  UPD     include/generated/uapi/linux/version.h
  CHK     include/generated/utsrelease.h
  UPD     include/generated/utsrelease.h
  CC      kernel/bounds.s
  GEN     include/generated/bounds.h
  CC      arch/x86/kernel/asm-offsets.s
  GEN     include/generated/asm-offsets.h
  CALL    scripts/checksyscalls.sh
make[2]: Leaving directory `/app/linux-3.18.3'
echo done > debian/stamp/conf/kernel-conf
make[1]: Leaving directory `/app/linux-3.18.3'
make -f debian/rules debian/stamp/conf/full-changelog
make[1]: Entering directory `/app/linux-3.18.3'
====== making target debian/stamp/conf/full-changelog [new prereqs: ]======
for file in ChangeLog  Control  Control.bin86 config templates.in rules; do       \
       cp -f  /usr/share/kernel-package/$file ./debian/;      \
  done
for dir  in Config docs examples ruleset scripts pkg po;  do        \
     cp -af /usr/share/kernel-package/$dir  ./debian/;        \
  done
install -p -m 755 /usr/share/kernel-package/rules debian/rules
sed         -e 's/=V/3.18.3-ix/g'  \
                -e 's/=D/3.18.3-ix-10.00.Custom/g'         -e 's/=A/amd64/g'  \
    -e 's/=SA//g'  \
    -e 's/=I//g'            \
    -e 's/=CV/3.18/g'         \
    -e 's/=M/Unknown Kernel Package Maintainer <unknown@unconfigured.in.etc.kernel-pkg.conf>/g'         \
    -e 's/=ST/linux/g'      -e 's/=B/x86_64/g'    \
                  /usr/share/kernel-package/Control > debian/control
sed -e 's/=V/3.18.3-ix/g' -e 's/=D/3.18.3-ix-10.00.Custom/g'        \
      -e 's/=A/amd64/g' -e 's/=M/Unknown Kernel Package Maintainer <unknown@unconfigured.in.etc.kernel-pkg.conf>/g' \
      -e 's/=ST/linux/g'   -e 's/=B/x86_64/g'       \
    /usr/share/kernel-package/changelog > debian/changelog
chmod 0644 debian/control debian/changelog
make -f debian/rules debian/stamp/conf/kernel-conf
make[2]: Entering directory `/app/linux-3.18.3'
make[2]: `debian/stamp/conf/kernel-conf' is up to date.
make[2]: Leaving directory `/app/linux-3.18.3'
make[1]: Leaving directory `/app/linux-3.18.3'
echo done > debian/stamp/conf/minimal_debian
exec debian/rules  APPEND_TO_VERSION=-ix  INITRD=YES  kernel_image
====== making target debian/stamp/conf/vars [new prereqs: ]======

====== making target debian/stamp/build/kernel [new prereqs: vars]======
This is kernel package version 12.036+nmu3.
restore_upstream_debianization
test ! -f scripts/package/builddeb.kpkg-dist || mv -f scripts/package/builddeb.kpkg-dist scripts/package/builddeb
test ! -f scripts/package/Makefile.kpkg-dist || mv -f scripts/package/Makefile.kpkg-dist scripts/package/Makefile
/usr/bin/make -j8 EXTRAVERSION=-ix  ARCH=x86_64 \
           bzImage
make[1]: Entering directory `/app/linux-3.18.3'
scripts/kconfig/conf --silentoldconfig Kconfig
make[1]: Leaving directory `/app/linux-3.18.3'
make[1]: Entering directory `/app/linux-3.18.3'
  CHK     include/config/kernel.release
  CHK     include/generated/uapi/linux/version.h
  CHK     include/generated/utsrelease.h
  HOSTCC  scripts/kallsyms
  HOSTCC  scripts/conmakehash
  HOSTCC  scripts/recordmcount
  HOSTCC  scripts/sortextable
  HOSTCC  scripts/genksyms/genksyms.o
  CC      scripts/mod/empty.o
  HOSTCC  scripts/selinux/genheaders/genheaders
  HOSTCC  scripts/selinux/mdp/mdp
  HOSTCC  scripts/mod/mk_elfconfig
  CC      scripts/mod/devicetable-offsets.s
  SHIPPED scripts/genksyms/parse.tab.c
  SHIPPED scripts/genksyms/lex.lex.c
  GEN     scripts/mod/devicetable-offsets.h
  MKELF   scripts/mod/elfconfig.h
  SHIPPED scripts/genksyms/keywords.hash.c
  HOSTCC  scripts/mod/modpost.o
```
...
```bash
chmod -R og=rX           /app/linux-3.18.3/debian/linux-image-3.18.3-ix
chown -R root:root         /app/linux-3.18.3/debian/linux-image-3.18.3-ix
dpkg --build           /app/linux-3.18.3/debian/linux-image-3.18.3-ix ..
dpkg-deb: building package `linux-image-3.18.3-ix' in `../linux-image-3.18.3-ix_3.18.3-ix-10.00.Custom_amd64.deb'.
make[2]: Leaving directory `/app/linux-3.18.3'
make[1]: Leaving directory `/app/linux-3.18.3'
/app
Congratulations! You just build a linux kernel.
Use the following command to install it: dpkg -i linux-image-3.18.3-ix*.deb

real  29m9.675s
user  106m11.252s
sys 11m12.928s
 ---> f2bc6838c313
Removing intermediate container df3c7c8e464d
Successfully built f2bc6838c313
Successfully built contyard.yourcompany.com/linux-kernel:...
```
```bash
make push
make[1]: Leaving directory `/home/gitlab_ci_runner/gitlab-ci-runner/tmp/builds/project-27'
make push
make[1]: Entering directory `/home/gitlab_ci_runner/gitlab-ci-runner/tmp/builds/project-27'
docker run -v /mnt/storage/:/mnt/storage contyard.yourcompany.com/linux-kernel: bash -c "cp *.deb /mnt/storage/"
make[1]: Leaving directory `/home/gitlab_ci_runner/gitlab-ci-runner/tmp/builds/project-27'
make clean
make[1]: Entering directory `/home/gitlab_ci_runner/gitlab-ci-runner/tmp/builds/project-27'
docker rmi -f contyard.yourcompany.com/linux-kernel:
Untagged: contyard.yourcompany.com/linux-kernel:latest
Deleted: f2bc6838c313d8631914614fdbee4d02bac7ff89d4eddf9943b4d51c54729cde
Deleted: 5a8446b33bebd1206336e8dfb313c4d6cf01c248f21ded23d3bc33915c6df452
Deleted: 1261802d8c8357cbeecc399565e07b407cb77020739a520dc9f186bafac400a3
Deleted: e86e27a7d592e11461dada61908100ceee03951d3777867e9883fe17518a7fe7
Deleted: 902c01ee6f862d684633f3dfc75a46b18a8fae18a87a6a22f8477ed5b019c630
make[1]: Leaving directory `/home/gitlab_ci_runner/gitlab-ci-runner/tmp/builds/project-27'

Build
```


```bash
/mnt/storage ~ ls
linux-image-3.18.3-ix_3.18.3-ix-10.00.Custom_amd64.deb
```
