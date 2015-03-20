#! /usr/bin/env bash
set -xe

# Set config options in kernel

# Manipulate options in a .config file from the command line.
# Usage:
# $myname options command ...
# commands:
#   --enable|-e option   Enable option
#   --disable|-d option  Disable option
#   --module|-m option   Turn option into a module
#   --set-str option string
#                        Set option to "string"
#   --set-val option value
#                        Set option to value
#   --undefine|-u option Undefine option
#   --state|-s option    Print state of option (n,y,m,undef)

#   --enable-after|-E beforeopt option
#                              Enable option directly after other option
#   --disable-after|-D beforeopt option
#                              Disable option directly after other option
#   --module-after|-M beforeopt option
#                              Turn option into module directly after other option

#   commands can be repeated multiple times

# options:
#   --file config-file   .config file to change (default .config)
#   --keep-case|-k       Keep next symbols' case (dont' upper-case it)

# $myname doesn't check the validity of the .config file. This is done at next
# make time.

# By default, $myname will upper-case the given symbol. Use --keep-case to keep
# the case of all following symbols unchanged.

# $myname uses 'CONFIG_' as the default symbol prefix. Set the environment
# variable CONFIG_ to the prefix to use. Eg.: CONFIG_="FOO_" $myname ...

# Debuginfo is only needed if you plan to use binary object tools like crash, kgdb, and SystemTap on the kernel.
scripts/config --disable DEBUG_INFO

### Virtualisation Helper ###

scripts/config --set-str CONFIG_UEVENT_HELPER_PATH ""
scripts/config --enable CONFIG_UEVENT_HELPER


### Storage Helper ###

scripts/config --enable CONFIG_SCSI \
               --enable CONFIG_SCSI_MQ_DEFAULT \
               --enable CONFIG_SATA_AHCI \
               --enable CONFIG_BLK_DEV_SD

### IPTABLES FOR 3.18+ ###

#
# IP: Netfilter Configuration
#

scripts/config  --enable CONFIG_NF_CONNTRACK_PROC_COMPAT


scripts/config  --module CONFIG_NF_DEFRAG_IPV4 \
                --module CONFIG_NF_CONNTRACK_IPV4 \
                --module CONFIG_NF_LOG_ARP \
                --module CONFIG_NF_LOG_IPV4 \
                --module CONFIG_NF_TABLES_IPV4 \
                --module CONFIG_NFT_CHAIN_ROUTE_IPV4 \
                --module CONFIG_NF_REJECT_IPV4 \
                --module CONFIG_NFT_REJECT_IPV4 \
                --module CONFIG_NF_TABLES_ARP \
                --module CONFIG_NF_NAT_IPV4 \
                --module CONFIG_NFT_CHAIN_NAT_IPV4 \
                --module CONFIG_NF_NAT_MASQUERADE_IPV4 \
                --module CONFIG_NFT_MASQ_IPV4 \
                --module CONFIG_NF_NAT_SNMP_BASIC \
                --module CONFIG_NF_NAT_PROTO_GRE \
                --module CONFIG_NF_NAT_PPTP \
                --module CONFIG_NF_NAT_H323 \
                --module CONFIG_IP_NF_IPTABLES \
                --module CONFIG_IP_NF_MATCH_AH \
                --module CONFIG_IP_NF_MATCH_ECN \
                --module CONFIG_IP_NF_MATCH_RPFILTER \
                --module CONFIG_IP_NF_MATCH_TTL \
                --module CONFIG_IP_NF_FILTER \
                --module CONFIG_IP_NF_TARGET_REJECT \
                --module CONFIG_IP_NF_TARGET_SYNPROXY \
                --module CONFIG_IP_NF_NAT \
                --module CONFIG_IP_NF_TARGET_MASQUERADE \
                --module CONFIG_IP_NF_TARGET_NETMAP \
                --module CONFIG_IP_NF_TARGET_REDIRECT \
                --module CONFIG_IP_NF_MANGLE \
                --module CONFIG_IP_NF_TARGET_CLUSTERIP \
                --module CONFIG_IP_NF_TARGET_ECN \
                --module CONFIG_IP_NF_TARGET_TTL \
                --module CONFIG_IP_NF_RAW \
                --module CONFIG_IP_NF_SECURITY \
                --module CONFIG_IP_NF_ARPTABLES \
                --module CONFIG_IP_NF_ARPFILTER \
                --module CONFIG_IP_NF_ARP_MANGLE

#
# IPv6: Netfilter Configuration
#
scripts/config  --module CONFIG_NF_DEFRAG_IPV6 \
                --module CONFIG_NF_CONNTRACK_IPV6 \
                --module CONFIG_NF_TABLES_IPV6 \
                --module CONFIG_NFT_CHAIN_ROUTE_IPV6 \
                --module CONFIG_NF_REJECT_IPV6 \
                --module CONFIG_NFT_REJECT_IPV6 \
                --module CONFIG_NF_LOG_IPV6 \
                --module CONFIG_NF_NAT_IPV6 \
                --module CONFIG_NFT_CHAIN_NAT_IPV6 \
                --module CONFIG_NF_NAT_MASQUERADE_IPV6 \
                --module CONFIG_NFT_MASQ_IPV6 \
                --module CONFIG_IP6_NF_IPTABLES \
                --module CONFIG_IP6_NF_MATCH_AH \
                --module CONFIG_IP6_NF_MATCH_EUI64 \
                --module CONFIG_IP6_NF_MATCH_FRAG \
                --module CONFIG_IP6_NF_MATCH_OPTS \
                --module CONFIG_IP6_NF_MATCH_HL \
                --module CONFIG_IP6_NF_MATCH_IPV6HEADER \
                --module CONFIG_IP6_NF_MATCH_MH \
                --module CONFIG_IP6_NF_MATCH_RPFILTER \
                --module CONFIG_IP6_NF_MATCH_RT \
                --module CONFIG_IP6_NF_TARGET_HL \
                --module CONFIG_IP6_NF_FILTER \
                --module CONFIG_IP6_NF_TARGET_REJECT \
                --module CONFIG_IP6_NF_TARGET_SYNPROXY \
                --module CONFIG_IP6_NF_MANGLE \
                --module CONFIG_IP6_NF_RAW \
                --module CONFIG_IP6_NF_SECURITY \
                --module CONFIG_IP6_NF_NAT \
                --module CONFIG_IP6_NF_TARGET_MASQUERADE \
                --module CONFIG_IP6_NF_TARGET_NPT

#
# DECnet: Netfilter Configuration
#
scripts/config  --module CONFIG_DECNET_NF_GRABULATOR \
                --module CONFIG_NF_TABLES_BRIDGE \
                --module CONFIG_NFT_BRIDGE_META \
                --module CONFIG_NFT_BRIDGE_REJECT \
                --module CONFIG_NF_LOG_BRIDGE \
                --module CONFIG_BRIDGE_NF_EBTABLES \
                --module CONFIG_BRIDGE_EBT_BROUTE \
                --module CONFIG_BRIDGE_EBT_T_FILTER \
                --module CONFIG_BRIDGE_EBT_T_NAT \
                --module CONFIG_BRIDGE_EBT_802_3 \
                --module CONFIG_BRIDGE_EBT_AMONG \
                --module CONFIG_BRIDGE_EBT_ARP \
                --module CONFIG_BRIDGE_EBT_IP \
                --module CONFIG_BRIDGE_EBT_IP6 \
                --module CONFIG_BRIDGE_EBT_LIMIT \
                --module CONFIG_BRIDGE_EBT_MARK \
                --module CONFIG_BRIDGE_EBT_PKTTYPE \
                --module CONFIG_BRIDGE_EBT_STP \
                --module CONFIG_BRIDGE_EBT_VLAN \
                --module CONFIG_BRIDGE_EBT_ARPREPLY \
                --module CONFIG_BRIDGE_EBT_DNAT \
                --module CONFIG_BRIDGE_EBT_MARK_T \
                --module CONFIG_BRIDGE_EBT_REDIRECT \
                --module CONFIG_BRIDGE_EBT_SNAT \
                --module CONFIG_BRIDGE_EBT_LOG \
                --module CONFIG_BRIDGE_EBT_NFLOG \
                --module CONFIG_IP_DCCP \
                --module CONFIG_INET_DCCP_DIAG

if [ "$GRSEC" = "true" ]; then

  ### GRSecurity ###

  scripts/config --set-val CONFIG_TASK_SIZE_MAX_SHIFT 47

  scripts/config --enable CONFIG_PAX_USERCOPY_SLABS \
                 --enable CONFIG_GRKERNSEC \
                 --enable CONFIG_GRKERNSEC_CONFIG_AUTO \
                 --enable CONFIG_GRKERNSEC_CONFIG_SERVER \
                 --enable CONFIG_GRKERNSEC_CONFIG_VIRT_GUEST \
                 --enable CONFIG_GRKERNSEC_CONFIG_VIRT_EPT \
                 --enable CONFIG_GRKERNSEC_CONFIG_VIRT_XEN \
                 --enable CONFIG_GRKERNSEC_CONFIG_PRIORITY_PERF

  #
  # Default Special Groups
  #
  scripts/config --set-val CONFIG_GRKERNSEC_PROC_GID 1001 \
                 --set-val CONFIG_GRKERNSEC_TPE_UNTRUSTED_GID 1005 \
                 --set-val CONFIG_GRKERNSEC_SYMLINKOWN_GID 1006

  #
  # PaX
  #
  scripts/config --enable CONFIG_PAX \
                 --enable CONFIG_PAX_EI_PAX \
                 --enable CONFIG_PAX_PT_PAX_FLAGS \
                 --enable CONFIG_PAX_XATTR_PAX_FLAGS \
                 --enable CONFIG_PAX_HAVE_ACL_FLAGS

  #
  # Non-executable pages
  #
  scripts/config --enable CONFIG_PAX_NOEXEC \
                 --enable CONFIG_PAX_PAGEEXEC \
                 --enable CONFIG_PAX_EMUTRAMP \
                 --enable CONFIG_PAX_MPROTECT

  scripts/config --set-str CONFIG_PAX_KERNEXEC_PLUGIN_METHOD ""

  #
  # Address Space Layout Randomization
  #
  scripts/config --enable CONFIG_PAX_ASLR \
                 --enable CONFIG_PAX_RANDKSTACK \
                 --enable CONFIG_PAX_RANDUSTACK \
                 --enable CONFIG_PAX_RANDMMAP

  #
  # Miscellaneous hardening features
  #
  scripts/config --enable CONFIG_PAX_REFCOUNT \
                 --enable CONFIG_PAX_USERCOPY \
                 --enable CONFIG_PAX_SIZE_OVERFLOW \
                 --enable CONFIG_PAX_LATENT_ENTROPY

  #
  # Memory Protections
  #
  scripts/config --enable CONFIG_GRKERNSEC_KMEM \
                 --enable CONFIG_GRKERNSEC_IO \
                 --enable CONFIG_GRKERNSEC_BPF_HARDEN \
                 --enable CONFIG_GRKERNSEC_PERF_HARDEN \
                 --enable CONFIG_GRKERNSEC_RAND_THREADSTACK \
                 --enable CONFIG_GRKERNSEC_PROC_MEMMAP \
                 --enable CONFIG_GRKERNSEC_KSTACKOVERFLOW \
                 --enable CONFIG_GRKERNSEC_BRUTE \
                 --enable CONFIG_GRKERNSEC_MODHARDEN \
                 --enable CONFIG_GRKERNSEC_HIDESYM \
                 --enable CONFIG_GRKERNSEC_RANDSTRUCT \
                 --enable CONFIG_GRKERNSEC_RANDSTRUCT_PERFORMANCE \
                 --enable CONFIG_GRKERNSEC_KERN_LOCKOUT

  #
  # Role Based Access Control Options
  #
  scripts/config --set-val CONFIG_GRKERNSEC_ACL_MAXTRIES 3 \
                 --set-val CONFIG_GRKERNSEC_ACL_TIMEOUT 30

  #
  # Filesystem Protections
  #
  scripts/config --enable CONFIG_GRKERNSEC_PROC \
                 --enable CONFIG_GRKERNSEC_PROC_USERGROUP \
                 --enable CONFIG_GRKERNSEC_PROC_ADD \
                 --enable CONFIG_GRKERNSEC_LINK \
                 --enable CONFIG_GRKERNSEC_SYMLINKOWN \
                 --enable CONFIG_GRKERNSEC_FIFO \
                 --enable CONFIG_GRKERNSEC_SYSFS_RESTRICT \
                 --enable CONFIG_GRKERNSEC_DEVICE_SIDECHANNEL \
                 --enable CONFIG_GRKERNSEC_CHROOT \
                 --enable CONFIG_GRKERNSEC_CHROOT_MOUNT \
                 --enable CONFIG_GRKERNSEC_CHROOT_DOUBLE \
                 --enable CONFIG_GRKERNSEC_CHROOT_PIVOT \
                 --enable CONFIG_GRKERNSEC_CHROOT_CHDIR \
                 --enable CONFIG_GRKERNSEC_CHROOT_CHMOD \
                 --enable CONFIG_GRKERNSEC_CHROOT_FCHDIR \
                 --enable CONFIG_GRKERNSEC_CHROOT_MKNOD \
                 --enable CONFIG_GRKERNSEC_CHROOT_SHMAT \
                 --enable CONFIG_GRKERNSEC_CHROOT_UNIX \
                 --enable CONFIG_GRKERNSEC_CHROOT_FINDTASK \
                 --enable CONFIG_GRKERNSEC_CHROOT_NICE \
                 --enable CONFIG_GRKERNSEC_CHROOT_SYSCTL \
                 --enable CONFIG_GRKERNSEC_CHROOT_CAPS \
                 --enable CONFIG_GRKERNSEC_CHROOT_INITRD

  #
  # Kernel Auditing
  #
  scripts/config --enable CONFIG_GRKERNSEC_RESLOG \
                 --enable CONFIG_GRKERNSEC_SIGNAL \
                 --enable CONFIG_GRKERNSEC_TIME \
                 --enable CONFIG_GRKERNSEC_PROC_IPADDR \
                 --enable CONFIG_GRKERNSEC_RWXMAP_LOG

  #
  # Executable Protections
  #
  scripts/config --enable CONFIG_GRKERNSEC_DMESG \
                 --enable CONFIG_GRKERNSEC_HARDEN_PTRACE \
                 --enable CONFIG_GRKERNSEC_PTRACE_READEXEC \
                 --enable CONFIG_GRKERNSEC_SETXID \
                 --enable CONFIG_GRKERNSEC_HARDEN_IPC \
                 --enable CONFIG_GRKERNSEC_TPE

  scripts/config --set-val CONFIG_GRKERNSEC_TPE_GID 1005

  #
  # Network Protections
  #
  scripts/config --enable CONFIG_GRKERNSEC_BLACKHOLE \
                 --enable CONFIG_GRKERNSEC_NO_SIMULT_CONNECT

  #
  # Physical Protections
  #
  scripts/config --enable CONFIG_GRKERNSEC_DENYUSB

  #
  # Sysctl Support
  #
  scripts/config --enable CONFIG_GRKERNSEC_SYSCTL \
                 --enable CONFIG_GRKERNSEC_SYSCTL_ON

  #
  # Logging Options
  #
  scripts/config --set-val CONFIG_GRKERNSEC_FLOODTIME 10 \
                 --set-val CONFIG_GRKERNSEC_FLOODBURST 6

fi
