#!/usr/bin/docker
# ________            ______             ____________________
# ___  __ \______________  /________________(eye)___ \_  ___/
# __  / / /  __ \  ___/_  //_/  _ \_  ___/_  /_  / / /____ \ 
# _  /_/ // /_/ / /__ _  ,<  /  __/  /   _  / / /_/ /____/ / 
# /_____/ \____/\___/ /_/|_| \___//_/    /_/  \____/ /____/  XNU-QEMU-ARM64
# 
# Repo:             https://github.com/sickcodes/Docker-eyeOS/
# Title:            iOS on Docker (Docker-eyeOS)
# Twitter:          @sickcodes          https://github.com/sickcodes
# GitHub:           @sickcodes          https://twitter.com/sickcodes
# Author:           Sick.Codes
# Version:          v1.0.12.1
# License:          GPLv3+

# Docker interpretation by @sickcodes: https://twitter.com/sickcodes
#
# https://twitter.com/sickcodes         @sickcodes
#
# All credits for iOS magic to:
# https://twitter.com/jonathanafek      @jonathanafek
# https://twitter.com/levaronsky        @levaronsky
# https://twitter.com/V3rochka          @V3rochka
# https://alephsecurity.com             @AlephSecurity
# https://twitter.com/alephsecurity

# Extra special hat tip to @MCApollo + @levaronsky for fixing the TCP tunnel for GNU/Linux!
# https://github.com/MCApollo      @MCApollo

# Follow for updates!
# @sickcodes https://twitter.com/sickcodes

# This Dockerfile hereby automates the installation of:
# aarch64-qemu-system for booting xnu-qemu-arm64/iOS

# Bells & Whistle
# - gdb debugging with gdb-multiarch

# Run Darwin Kernel Version 18.2.0 xnu-4903.222.5~1/RELEASE_ARM64_S8000 for iPhone8,2
# Thru QEMU + Docker!

# Run:
#
# docker run -it --privileged \
#     --device /dev/kvm \
#     -e RAM=6 \
#     -e HFS_MAIN=./images/hfs.main \
#     -e HFS_SEC=./images/hfs.sec \
#     -p 2222:2222 \
#     -v "$PWD:/home/arch/docker-eyeos/images" \
#     -e "DISPLAY=${DISPLAY:-:0.0}" \
#     -v /tmp/.X11-unix:/tmp/.X11-unix \
#     -p 1233:1234 \
#     -e GDB_ARGS='-S -s' \
#     sickcodes/docker-eyeos:latest
#
#       
# Or build:
#
#       docker build -t docker-eyeos .
#       
#       docker build --build-arg GDB_MULTIARCH=false -t docker-eyeos .
#       


FROM archlinux:latest
MAINTAINER '@sickcodes' <https://twitter.com/sickcodes>
LABEL maintainer "https://github.com/sickcodes"

USER root

#### IPSW SPECIFICS
# build args to become more generic platform for debugging any iOS version

# IPSW url
ARG IPSW=http://updates-http.cdn-apple.com/2018FallFCS/fullrestores/091-91479/964118EC-D4BE-11E8-BC75-A45C715A3354/iPhone_5.5_12.1_16B92_Restore.ipsw
# find name after unzipping the IPSW above
ARG KERNEL_CACHE_RAW=kernelcache.release.n66
# located at "./Firmware/all_flash/" after unzipping the IPSW
ARG DEVICE_TREE_IM4P=DeviceTree.n66ap.im4p
# DEVICE MODEL
ENV PHONE_MODEL=iPhone6splus-n66-s8000


#### IOS_SDK FOR BUILDING TCP-TUNNEL (FUTURE)
# choose SDK version from
# https://github.com/theos/sdks
ARG IOS_SDK=./sdks/iPhoneOS11.2.sdk
# Or from 
# https://github.com/xybp888/iOS-SDKs.git
# ARG IOS_SDK=./iOS-SDKs/iPhoneOS13.7.sdk

#### GDB INSTALLATION ON OR OFF
# speed up build without gdb
# docker build --build-arg GDB_MULTIARCH=false -t docker-eyeos .
ARG GDB_MULTIARCH=true



# WORKING DIRECTORY INSIDE THE CONTAINER
ENV WD=/home/arch/docker-eyeos

ENV XNU_SOURCES="${WD}/darwin-xnu"
ENV KERNEL_SYMBOLS_FILE="${WD}/symbols.nm"
ENV QEMU_DIR="${WD}/xnu-qemu-arm64"
ENV IOS_DIR="${WD}"
ENV NUM_BLOCK_DEVS=2
ENV KERNEL_CACHE="${WD}/${KERNEL_CACHE_RAW}.out"
ENV DTB_FIRMWARE="${WD}/Firmware/all_flash/${DEVICE_TREE_IM4P}.out"
ENV DRIVER_FILENAME="${WD}/aleph_bdev_drv.bin"
ENV HFS_MAIN="${WD}/hfs.main"
ENV HFS_SEC="${WD}/hfs.sec"
ENV SDK_DIR="${WD}/${IOS_SDK}"

ENV DISPLAY=:0.0
ENV GDB_PORT=1234
ENV GDB=false

WORKDIR /root

ARG RANKMIRRORS=no
ARG MIRROR_COUNTRY=US
ARG MIRROR_COUNT=10

# Arch Linux server mirrors for faster builds
RUN if [[ "${RANKMIRRORS}" = yes ]]; then { pacman -Sy wget --noconfirm || pacman -Syu wget --noconfirm ; } \
    ; wget -O ./rankmirrors "https://raw.githubusercontent.com/sickcodes/Docker-OSX/master/rankmirrors" \
    ; wget -O- "https://www.archlinux.org/mirrorlist/?country=${MIRROR_COUNTRY:-US}&protocol=https&use_mirror_status=on" \
    | sed -e 's/^#Server/Server/' -e '/^#/d' \
    | head -n "$((${MIRROR_COUNT:-10}+1))" \
    | bash ./rankmirrors --verbose --max-time 5 - > /etc/pacman.d/mirrorlist \
    && tee -a /etc/pacman.d/mirrorlist <<< 'Server = http://mirrors.evowise.com/archlinux/$repo/os/$arch' \
    && tee -a /etc/pacman.d/mirrorlist <<< 'Server = http://mirror.rackspace.com/archlinux/$repo/os/$arch' \
    && tee -a /etc/pacman.d/mirrorlist <<< 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch' \
    && cat /etc/pacman.d/mirrorlist; fi

RUN tee -a /etc/pacman.conf <<< '[community-testing]' \
    && tee -a /etc/pacman.conf <<< 'Include = /etc/pacman.d/mirrorlist'
# RUN tee -a /etc/pacman.conf <<< '[blackarch]' \
#     && tee -a /etc/pacman.conf <<< 'Include = /etc/pacman.d/mirrorlist'

RUN pacman -Syyuu --needed --noconfirm sudo git python3 llvm aarch64-linux-gnu-gcc python-pyasn1 unzip fakeroot \
    base-devel go wget make cmake clang flex bison icu fuse linux-headers gcc-multilib lib32-gcc-libs \
    pkg-config fontconfig cairo libtiff python2 mesa llvm lld libbsd libxkbfile libxcursor libxext \
    libxkbcommon libxrandr leatherman gcc fuse-overlayfs qemu qemu-arch-extra qemu-guest-agent libvirt \
    bsdiff openssh \
    && useradd arch \
    && echo 'arch ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && mkdir -p /home/arch \
    chown arch:arch /home/arch

USER arch
WORKDIR /home/arch
RUN sudo chown -R arch:arch /home/arch
RUN git clone https://aur.archlinux.org/yay.git
WORKDIR /home/arch/yay
RUN makepkg -si --noconfirm

WORKDIR /home/arch
RUN yay --getpkgbuild hfsprogs
WORKDIR /home/arch/hfsprogs
RUN makepkg -si --noconfirm
# RUN wget "https://src.fedoraproject.org/rpms/hfsplus-tools/raw/master/f/hfsplus-tools-sysctl.patch"
# RUN sed -i -e 's/\ \ patch\ \-p0\ \-i\ /patch\ \-p1\ \-i\ \"\${srcdir}\/\.\.\/hfsplus\-tools\-sysctl\.patch\"\npatch\ \-p0\ \-i\ /' PKGBUILD \
#     ; makepkg -si --noconfirm \
#     && echo 'hfsprogs patch thanks @keithspg https://aur.archlinux.org/packages/hfsprogs/#comment-765637'

WORKDIR /home/arch
RUN yay --getpkgbuild gdb-multiarch
WORKDIR /home/arch/gdb-multiarch
RUN if [[ "${GDB_MULTIARCH}" = true ]]; then makepkg --skipinteg --skippgpcheck --skipchecksums -si --noconfirm; else echo "Skipping GDB"; fi

# allow ssh to container
USER root
WORKDIR /root
RUN mkdir .ssh \
    && chmod 700 .ssh

WORKDIR /root/.ssh
RUN touch authorized_keys \
    && chmod 644 authorized_keys

RUN mkdir -p /etc/ssh
WORKDIR /etc/ssh
RUN tee -a sshd_config <<< 'AllowTcpForwarding yes' \
    && tee -a sshd_config <<< 'PermitTunnel yes' \
    && tee -a sshd_config <<< 'X11Forwarding yes' \
    && tee -a sshd_config <<< 'PasswordAuthentication yes' \
    && tee -a sshd_config <<< 'PermitRootLogin yes' \
    && tee -a sshd_config <<< 'PubkeyAuthentication yes' \
    && tee -a sshd_config <<< 'HostKey /etc/ssh/ssh_host_rsa_key' \
    && tee -a sshd_config <<< 'HostKey /etc/ssh/ssh_host_ecdsa_key' \
    && tee -a sshd_config <<< 'HostKey /etc/ssh/ssh_host_ed25519_key'

USER arch

RUN mkdir -p /home/arch/docker-eyeos \
    && mkdir -p /home/arch/docker-eyeos/images

# start workin
WORKDIR /home/arch/docker-eyeos
RUN wget "${IPSW}"

RUN unzip "$(basename "${IPSW}")" \
    && rm -f "${IPSW}"

WORKDIR /home/arch/docker-eyeos
RUN git clone https://github.com/apple/darwin-xnu.git
RUN git clone https://github.com/theos/sdks.git

# temporarily removed to reduce image size until full build on Linux is complete
# RUN git clone https://github.com/xybp888/iOS-SDKs.git

WORKDIR /home/arch/docker-eyeos
RUN git clone --recursive https://github.com/alephsecurity/xnu-qemu-arm64.git
WORKDIR /home/arch/docker-eyeos/xnu-qemu-arm64
RUN git reset --hard HEAD^1 \
    && git checkout master \
    && git remote add sickcodes https://github.com/sickcodes/xnu-qemu-arm64.git \
    && git remote add mcapollo https://github.com/MCApollo/xnu-qemu-arm64.git \
    && git fetch --all \
    && git reset --hard HEAD^1 \
    && git pull --all \
    && git checkout bbd2d9955021d72d5dbfccc94a034cc671c41181 \
    && echo 'Thank you MCApollo && Aleph Security (Lev Aronsky, Jonathan Afek, Vera Mens!)'

WORKDIR /home/arch/docker-eyeos
RUN git clone https://github.com/alephsecurity/xnu-qemu-arm64-tools.git
WORKDIR /home/arch/docker-eyeos/xnu-qemu-arm64-tools
RUN git reset --hard HEAD^1 \
    && git checkout master \
    && git remote add sickcodes https://github.com/sickcodes/xnu-qemu-arm64-tools.git \
    && git remote add mcapollo https://github.com/MCApollo/xnu-qemu-arm64-tools.git \
    && git fetch --all \
    && git reset --hard HEAD^1 \
    && git pull --all \
    && git checkout 10ce50869ce573725774cd0e9a2a431ff3beec5c \
    && echo 'Thank you MCApollo && Aleph Security (Lev Aronsky, Jonathan Afek, Vera Mens!)'

WORKDIR /home/arch/docker-eyeos
RUN python xnu-qemu-arm64-tools/bootstrap_scripts/asn1kerneldecode.py "${KERNEL_CACHE_RAW}" "${KERNEL_CACHE_RAW}.asn1decoded"
RUN python xnu-qemu-arm64-tools/bootstrap_scripts/decompress_lzss.py "${KERNEL_CACHE_RAW}.asn1decoded" "${KERNEL_CACHE_RAW}.out"
RUN python xnu-qemu-arm64-tools/bootstrap_scripts/asn1dtredecode.py "Firmware/all_flash/${DEVICE_TREE_IM4P}" "Firmware/all_flash/${DEVICE_TREE_IM4P}.out"

# extract symbols
RUN llvm-nm "${KERNEL_CACHE_RAW}.out" > symbols.nm
RUN cp symbols.nm ./xnu-qemu-arm64
RUN cp symbols.nm ./images

WORKDIR /home/arch
RUN yay --getpkgbuild aarch64-none-elf-gcc-bin
WORKDIR /home/arch/aarch64-none-elf-gcc-bin
RUN makepkg -si --noconfirm

WORKDIR /home/arch/docker-eyeos/
RUN make -C xnu-qemu-arm64-tools/aleph_bdev_drv
RUN cp ./xnu-qemu-arm64-tools/aleph_bdev_drv/bin/aleph_bdev_drv.bin .

USER arch

WORKDIR /home/arch/docker-eyeos

# redefine env for arch user
ENV WD="/home/arch/docker-eyeos"

ENV XNU_SOURCES="${WD}/darwin-xnu"
ENV KERNEL_SYMBOLS_FILE="${WD}/symbols.nm"
ENV QEMU_DIR="${WD}/xnu-qemu-arm64"
ENV IOS_DIR="${WD}"
ENV NUM_BLOCK_DEVS=2
ENV KERNEL_CACHE="${WD}/${KERNEL_CACHE_RAW}.out"
ENV DTB_FIRMWARE="${WD}/Firmware/all_flash/${DEVICE_TREE_IM4P}.out"
ENV DRIVER_FILENAME="${WD}/aleph_bdev_drv.bin"
ENV HFS_MAIN="${WD}/hfs.main"
ENV HFS_SEC="${WD}/hfs.sec"
ENV SDK_DIR="${WD}/${IOS_SDK}"
ENV PHONE_MODEL="${PHONE_MODEL}"

ENV DISPLAY=:0.0
ENV GDB_PORT=1234
ENV GDB=true

WORKDIR /home/arch/docker-eyeos/xnu-qemu-arm64

RUN echo "Switching to The Lost Commit by @MCApollo" \
    && git checkout -f c84d3e3a71a9454a6222418fe726729ff2d0eae3

RUN sudo make distclean \
    && sudo make clean \
    && sudo ./configure --target-list=aarch64-softmmu \
    --disable-capstone \
    --disable-pie \
    --disable-slirp \
    --disable-werror

RUN sudo make --ignore-errors -j8

WORKDIR /home/arch/docker-eyeos

RUN touch enable-ssh.sh \
    && chmod +x ./enable-ssh.sh \
    && tee -a enable-ssh.sh <<< 'sudo /usr/bin/ssh-keygen -A' \
    && tee -a enable-ssh.sh <<< 'nohup sudo /usr/bin/sshd -D &'

RUN touch ./Launch.sh \
    && chmod +x Launch.sh \
    && tee -a Launch.sh <<< 'until [[ $(sudo fsck.hfsplus -fp ${HFS_MAIN}) ]]; do' \
    && tee -a Launch.sh <<< '    echo "Repairing hfs.sec..."' \
    && tee -a Launch.sh <<< 'done' \
    && tee -a Launch.sh <<< 'until [[ $(sudo fsck.hfsplus -fp ${HFS_SEC}) ]]; do' \
    && tee -a Launch.sh <<< '    echo "Repairing hfs.main..."' \
    && tee -a Launch.sh <<< 'done' \
    && tee -a Launch.sh <<< 'sudo xnu-qemu-arm64/aarch64-softmmu/qemu-system-aarch64 ${GDB_ARGS} \' \
    && tee -a Launch.sh <<< '-M ${PHONE_MODEL},kernel-filename=${KERNEL_CACHE},dtb-filename=${DTB_FIRMWARE},driver-filename=${DRIVER_FILENAME},qc-file-0-filename=${HFS_MAIN},qc-file-1-filename=${HFS_SEC},kern-cmd-args="debug=0x8 kextlog=0xfff cpus=1 rd=disk0 serial=2",xnu-ramfb=off \' \
    && tee -a Launch.sh <<< '    -cpu max \' \
    && tee -a Launch.sh <<< '    -m ${RAM:-6}G \' \
    && tee -a Launch.sh <<< '    -serial mon:stdio \' \
    && tee -a Launch.sh <<< '    -vga std \' \
    && tee -a Launch.sh <<< '    ${EXTRA:-}'

VOLUME ["/tmp/.X11-unix"]

CMD ./enable-ssh.sh \
    && envsubst < ./Launch.sh | sudo bash

