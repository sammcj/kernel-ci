FROM debian:jessie
MAINTAINER Sam McLeod

ENV DEBIAN_FRONTEND noninteractive

# Install Debian packages
RUN apt-get -y update && apt-get -y install openssh-client coreutils fakeroot build-essential kernel-package wget xz-utils gnupg bc devscripts apt-utils initramfs-tools aria2 && apt-get clean
RUN mkdir -p /mnt/storage

WORKDIR /app

ADD * /app/

RUN chmod +x buildkernel.sh && ./buildkernel.sh
