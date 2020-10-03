#!/bin/bash
# Copyright (C) 2020 Sick.Codes - All Rights Reserved
# Title:            XNU Disk Builder for Docker-eyeOS
# License: GPLv3
# Credits: 
# Notice Written by Sick.Codes <info@sick.codes>, October 2020

# Twitter:          @sickcodes          https://github.com/sickcodes
# GitHub:           @sickcodes          https://twitter.com/sickcodes
# Author:           Sick.Codes
# Version:          v1.0.12.1
# License:          GPLv3+

# Authors:          Sick.Codes https://github.com/sickcodes
# Original Authors: @AlephSecurity
# Based ON:         https://github.com/alephsecurity/xnu-qemu-arm64/wiki/Build-iOS-on-QEMU
# Author:           Vera Ashkenazi via Aleph Security
# License:          GPLv2 see https://github.com/alephsecurity/xnu-qemu-arm64/blob/master/LICENSE

# Download homebrew from https://brew.sh/

# be in bash 5 and run:
# bash ./osx-build-xnu-disks.sh

if [[ "${BASH_VERSION}" != 5* ]]; then 
    cat <<'EOF'
    # install brew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    # switch from bash 3 to bash 5
    brew install bash 
    sudo chsh -s /usr/local/bin/bash root
    echo /usr/local/bin/bash' >> ~/.zshrc
    echo 'export PATH="/usr/local/opt/unzip/bin:$PATH"' >> ~/.bashrc
    . ~/.zshrc
EOF
    exit 1
fi

echo BUILD ARGS

IPSW=http://updates-http.cdn-apple.com/2018FallFCS/fullrestores/091-91479/964118EC-D4BE-11E8-BC75-A45C715A3354/iPhone_5.5_12.1_16B92_Restore.ipsw
IPSW_BASENAME="$(basename "${IPSW}")"
RAM_DISK=048-32651-104.dmg              # RAM DISK, 100mb or so
IOS_DISK=048-31952-103.dmg              # BIGGEST DISK, few GB
DUD_DISK=048-32459-105.dmg              # unused
RAM_DISK_NAME=PeaceB16B92.arm64UpdateRamDisk
IOS_DISK_NAME=PeaceB16B92.N56N66OS
KERNEL_CACHE_RAW=kernelcache.release.n66
DEVICE_TREE_IM4P=DeviceTree.n66ap.im4p
PHONE_MODEL=iPhone6splus-n66-s8000
IOD_SDK="$PWD/sdks/iPhoneOS11.2.sdk"

PATCH_LAUNCHD=true
PATHCED_LAUNCHD=https://raw.githubusercontent.com/sickcodes/Docker-eyeOS/master/patched/launchd.patched.bin

PATCH_DYLD=true
PATCHED_DYLD=https://raw.githubusercontent.com/sickcodes/Docker-eyeOS/master/patched/dyld.patched.bin

brew install python3 pkg-config pixman wget git unzip iproute2mac gcc glib rsync


# download iOS 12.1 for iPhone 6S
[[ -e "${IPSW_BASENAME}" ]] || wget "${IPSW}"
unzip -o "${IPSW_BASENAME}"

# clone required repos
git clone https://github.com/alephsecurity/xnu-qemu-arm64-tools.git
git clone https://github.com/apple/darwin-xnu.git 
git clone --recursive https://github.com/alephsecurity/xnu-qemu-arm64.git

cat <<'EOF'
Docker-eyeOS, a Dockerfile for Aleph Security's xnu-qemu-arm64 & xnu-qemu-arm64-tools
Dockerfile Author: @sickcodes -  https://github.com/sickcodes - https://twitter.com/sickcodes          

Upstream Credits:
HUGE Thank you to the research team @AlephSecurity for giving birth to this rendition!

https://alephsecurity.com
https://github.com/alephsecurity/
https://twitter.com/alephsecurity

The team (that I know) who helped on getting XNU to run like this on Linux out of the box support:
@JonathanAfek   https://github.com/jonyafek     https://twitter.com/JonathanAfek
@aronsky        https://github.com/aronsky      https://twitter.com/levaronsky
@V3rochka       https://github.com/V3rochka     https://twitter.com/V3rochka

Extra special hat tip to @MCApollo (iOS jailbreaker + lurker) for working on TCP-Tunnel.
@MCApollo       https://github.com/MCApollo     

EOF

# There are 4 states that need to be in place
# Darwin xnu-qemu-arm64-tools should be on git checkout sickcodes/master || git checkout 10ce50869ce573725774cd0e9a2a431ff3beec5c
# Darwin xnu-qemu-arm64 should be on git checkout sickcodes/master || git checkout bbd2d9955021d72d5dbfccc94a034cc671c41181
# Linux xnu-qemu-arm64-tools should be on git checkout sickcodes/master || git checkout 10ce50869ce573725774cd0e9a2a431ff3beec5c
# Linux xnu-qemu-arm64 should be on git checkout sickcodes/missing-commit || git checkout c84d3e3a71a9454a6222418fe726729ff2d0eae3


# DARWIN STATES
cd ./xnu-qemu-arm64-tools
git reset --hard HEAD^1
git checkout master
git remote add sickcodes https://github.com/sickcodes/xnu-qemu-arm64-tools.git
git remote add mcapollo https://github.com/MCApollo/xnu-qemu-arm64-tools.git
git fetch --all
git reset --hard HEAD^1
git pull --all
git checkout 10ce50869ce573725774cd0e9a2a431ff3beec5c
echo 'Thank you MCApollo && Lev Aronsky!'
cd ..

cd ./xnu-qemu-arm64
git reset --hard HEAD^1
git checkout master
git remote add sickcodes https://github.com/sickcodes/xnu-qemu-arm64.git
git remote add mcapollo https://github.com/MCApollo/xnu-qemu-arm64.git
git fetch --all
git reset --hard HEAD^1
git pull --all
git checkout bbd2d9955021d72d5dbfccc94a034cc671c41181
echo 'Thank you MCApollo && Lev Aronsky!'
cd ..

pip3 install pyasn1 numpy

python3 xnu-qemu-arm64-tools/bootstrap_scripts/asn1kerneldecode.py "${KERNEL_CACHE_RAW}" "${KERNEL_CACHE_RAW}.asn1decoded"
python3 xnu-qemu-arm64-tools/bootstrap_scripts/decompress_lzss.py "${KERNEL_CACHE_RAW}.asn1decoded" "${KERNEL_CACHE_RAW}.out"
python3 xnu-qemu-arm64-tools/bootstrap_scripts/asn1dtredecode.py "Firmware/all_flash/${DEVICE_TREE_IM4P}" "Firmware/all_flash/${DEVICE_TREE_IM4P}.out"


# get symbols, FYI need to use llvm-nm on Linux
nm "${KERNEL_CACHE_RAW}.out" > symbols.nm 2>/dev/null || llvm-nm "${KERNEL_CACHE_RAW}.out" > symbols.nm

export XNU_SOURCES=$PWD/darwin-xnu
export KERNEL_SYMBOLS_FILE=$PWD/symbols.nm
export QEMU_DIR=$PWD/xnu-qemu-arm64
export NUM_BLOCK_DEVS=2

# https://github.com/SergioBenitez/homebrew-osxct.git
brew tap SergioBenitez/osxct
brew install aarch64-none-elf
echo "Thank you Sergio Benitez! https://github.com/SergioBenitez"

# make the driver
# will NOT work on GNU right now, but will work on OSX
make -C xnu-qemu-arm64-tools/aleph_bdev_drv clean
make -C xnu-qemu-arm64-tools/aleph_bdev_drv

cp ./xnu-qemu-arm64-tools/aleph_bdev_drv/bin/aleph_bdev_drv.bin ./


# remove disks from any previous runs
while read DISK_NAME; do
    echo "$DISK_NAME"
    sudo hdiutil detach "/Volumes/${DISK_NAME}"
done <<< $(ls /Volumes | grep "${RAM_DISK_NAME}\|${IOS_DISK_NAME}")

python3 xnu-qemu-arm64-tools/bootstrap_scripts/asn1rdskdecode.py "./${RAM_DISK}" "./${RAM_DISK}.out"
cp "./${RAM_DISK}.out" ./hfs.main

hdiutil resize -size 6G -imagekey diskimage-class=CRawDiskImage ./hfs.main
hdiutil attach -imagekey diskimage-class=CRawDiskImage ./hfs.main
hdiutil attach "./${IOS_DISK}"

sudo diskutil enableownership "/Volumes/${RAM_DISK_NAME}/"
sudo rm -rf "/Volumes/${RAM_DISK_NAME}/"*
sudo rsync -av "/Volumes/${IOS_DISK_NAME}/"* "/Volumes/${RAM_DISK_NAME}/"
sudo chown root "/Volumes/${RAM_DISK_NAME}/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64"

sudo rm -rf "/Volumes/${RAM_DISK_NAME}/private/var/"*

git clone https://github.com/jakeajames/rootlessJB
cd rootlessJB/rootlessJB/bootstrap/tars/
tar xvf iosbinpack.tar
sudo cp -R iosbinpack64 "/Volumes/${RAM_DISK_NAME}/"
echo "Thank you @jakeajames!"
cd -

brew install dropbear
dropbearkey -t rsa -f ./dropbear_key | grep "^ssh-rsa " >> dropbear_key.pub
sudo mkdir -p "/Volumes/${RAM_DISK_NAME}/etc/dropbear"
sudo cp dropbear_key "/Volumes/${RAM_DISK_NAME}/etc/dropbear/dropbear_key"
sudo cp dropbear_key.pub "/Volumes/${RAM_DISK_NAME}/etc/dropbear/dropbear_key.pub"

### MAC

# drop Dropbear keys inside the 
if [[ $(uname) = Linux ]]; then
    sudo rm ./dropbear_ecdsa_host_key
    sudo rm ./dropbear_rsa_host_key
    sudo rm ./dropbear_ed25519_host_key
    sudo mkdir -p "/run/media/user/${RAM_DISK_NAME}/var/dropbear/"
    sudo mkdir -p /"run/media/user/${RAM_DISK_NAME}/etc/dropbear/"

    sudo dropbearkey -t ecdsa -f ./dropbear_ecdsa_host_key | grep "^ecdsa-sha2-nistp256 " >> dropbear_ecdsa_host_key.pub
    sudo dropbearkey -t rsa -f ./dropbear_rsa_host_key | grep "^ssh-rsa " >> dropbear_rsa_host_key.pub
    sudo dropbearkey -t ed25519 -f ./dropbear_ed25519_host_key | grep "^ssh-ed25519 " >> dropbear_ed25519_host_key.pub

    KEY_FILES=(
dropbear_ecdsa_host_key
dropbear_ecdsa_host_key.pub
dropbear_rsa_host_key
dropbear_rsa_host_key.pub
dropbear_ed25519_host_key
dropbear_ed25519_host_key.pub
)
    for KEY_FILE in "${KEY_FILES[@]}"; do
        sudo cp -f "${KEY_FILE}" "/run/media/user/${RAM_DISK_NAME}/var/dropbear/${KEY_FILE}"
        sudo cp -f "${KEY_FILE}" "/run/media/user/${RAM_DISK_NAME}/etc/dropbear/${KEY_FILE}"
    done

else
    sudo mkdir -p "/Volumes/${RAM_DISK_NAME}/var/dropbear/"
    sudo mkdir -p "/Volumes/${RAM_DISK_NAME}/etc/dropbear/"
    sudo dropbearkey -t dss -f "/Volumes/${RAM_DISK_NAME}/etc/dropbear/dropbear_dss_host_key"
    sudo dropbearkey -t rsa -f "/Volumes/${RAM_DISK_NAME}/etc/dropbear/dropbear_rsa_host_key"
    sudo dropbearkey -t ecdsa -f "/Volumes/${RAM_DISK_NAME}/etc/dropbear/dropbear_ecdsa_host_key"
    sudo dropbearkey -t ed25519 -f "/Volumes/${RAM_DISK_NAME}/etc/dropbear/dropbear_ed25519_host_key"
    sudo dropbearkey -t dss -f "/Volumes/${RAM_DISK_NAME}/var/dropbear/dropbear_dss_host_key"
    sudo dropbearkey -t rsa -f "/Volumes/${RAM_DISK_NAME}/var/dropbear/dropbear_rsa_host_key"
    sudo dropbearkey -t ecdsa -f "/Volumes/${RAM_DISK_NAME}/var/dropbear/dropbear_ecdsa_host_key"
    sudo dropbearkey -t ed25519 -f "/Volumes/${RAM_DISK_NAME}/var/dropbear/dropbear_ed25519_host_key"
fi

# sudo tee /Volumes/${RAM_DISK_NAME}/iosbinpack64/binlink.sh <<EOF
# export PATH=/iosbinpack64/usr/bin:/iosbinpack64/bin:/iosbinpack64/usr/sbin:/iosbinpack64/sbin:\$PATH
# EOF

# sudo chmod +x /Volumes/${RAM_DISK_NAME}/iosbinpack64/binlink.sh

# PASTE THESE ONE BY ONE, THEY MAY NOT PASTE CORRECTLY IF OTHERWISE

sudo tee "/Volumes/${RAM_DISK_NAME}/System/Library/LaunchDaemons/bash.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>EnablePressuredExit</key>
    <false/>
    <key>Label</key>
    <string>com.apple.bash</string>
    <key>POSIXSpawnType</key>
    <string>Interactive</string>
    <key>ProgramArguments</key>
    <array>
        <string>/iosbinpack64/bin/bash</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/dev/console</string>
    <key>StandardInPath</key>
    <string>/dev/console</string>
    <key>StandardOutPath</key>
    <string>/dev/console</string>
    <key>Umask</key>
    <integer>0</integer>
    <key>UserName</key>
    <string>root</string>
</dict>
</plist>
EOF


sudo tee "/Volumes/${RAM_DISK_NAME}/System/Library/LaunchDaemons/mount_sec.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.apple.mount_sec</string>
    <key>EnablePressuredExit</key>
    <false/>
    <key>EnableTransactions</key>
    <false/>
    <key>HighPriorityIO</key>
    <true/>
    <key>Label</key>
    <string>mount_sec</string>
    <key>POSIXSpawnType</key>
    <string>Interactive</string>
    <key>ProgramArguments</key>
    <array>
        <string>/sbin/mount</string>
        <string>/private/var</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>Umask</key>
    <integer>0</integer>
    <key>UserName</key>
    <string>root</string>
</dict>
</plist>
EOF


sudo tee "/Volumes/${RAM_DISK_NAME}/System/Library/LaunchDaemons/tcptunnel.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.apple.tcptunnel</string>
    <key>EnablePressuredExit</key>
    <false/>
    <key>EnableTransactions</key>
    <false/>
    <key>HighPriorityIO</key>
    <false/>
    <key>KeepAlive</key>
    <true/>
    <key>Label</key>
    <string>TcpTunnel</string>
    <key>POSIXSpawnType</key>
    <string>Interactive</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/tunnel</string>
        <string>2222:127.0.0.1:22</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>Umask</key>
    <integer>0</integer>
    <key>UserName</key>
    <string>root</string>
</dict>
</plist>
EOF


sudo tee "/Volumes/${RAM_DISK_NAME}/System/Library/LaunchDaemons/dropbear.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.apple.dropbear</string>
    <key>EnablePressuredExit</key>
    <false/>
    <key>EnableTransactions</key>
    <false/>
    <key>HighPriorityIO</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>Label</key>
    <string>Dropbear</string>
    <key>POSIXSpawnType</key>
    <string>Interactive</string>
    <key>ProgramArguments</key>
    <array>
        <string>/iosbinpack64/usr/local/bin/dropbear</string>
        <string>--shell</string>
        <string>/iosbinpack64/bin/bash</string>
        <string>-R</string>
        <string>-E</string>
        <string>-F</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>Umask</key>
    <integer>0</integer>
    <key>UserName</key>
    <string>root</string>
</dict>
</plist>
EOF


# sudo sed -i -e 's%REPLACE_ME%/iosbinpack64%g' /Volumes/${RAM_DISK_NAME}/iosbinpack64/dropbear.plist

mkdir -p jtool
cd jtool
wget http://newosxbook.com/tools/jtool.tar
tar xvf jtool.tar
sudo chmod +x *
sudo cp jtool /usr/local/bin
cd -

git clone https://github.com/theos/sdks.git

export XNU_SOURCES="$PWD/darwin-xnu"
export KERNEL_SYMBOLS_FILE="$PWD/symbols.nm"
export QEMU_DIR="$PWD/xnu-qemu-arm64"
export QEMU_TOOLS_DIR="$PWD/xnu-qemu-arm64-tools/"
export NUM_BLOCK_DEVS=2
export KERNEL_CACHE="$PWD/${KERNEL_CACHE_RAW}.out"
export DTB_FIRMWARE="$PWD/Firmware/all_flash/${DEVICE_TREE_IM4P}.out"
export DRIVER_FILENAME="$PWD/aleph_bdev_drv.bin"
export IOS_DIR="$PWD"
export HFS_MAIN="$PWD/hfs.main"
export HFS_SEC="$PWD/hfs.sec"
export SDK_DIR="${IOD_SDK}"

# Update tree & Build the Custom Block Device Driver
# cd "${QEMU_TOOLS_DIR}"
# git pull
cd "${IOS_DIR}"

echo "Thanks you @Maroc-OS for these edits!"

make -C "${QEMU_TOOLS_DIR}/aleph_bdev_drv clean"
make -C "${QEMU_TOOLS_DIR}/aleph_bdev_drv"
cp "${QEMU_TOOLS_DIR}/aleph_bdev_drv/bin/aleph_bdev_drv.bin" "${DRIVER_FILENAME}"

# Update tree & Build XNU QEMU for iOS
cd ${QEMU_DIR}
git pull --all
cd -

tee ./ent.xml <<EOF
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>platform-application</key>
        <true/>
        <key>com.apple.private.security.container-required</key>
        <false/>
    </dict>
</plist>
EOF


##### HELP WANTED
##### IF YOU CAN MAKE THIS ON LINUX THEN THE WHOLE THING CAN BE DONE IN THE DOCKER WITHOUT OSX
cd xnu-qemu-arm64-tools/tcp-tunnel

make distclean
make clean
make
make install

cd -

# re attach
hdiutil attach -imagekey diskimage-class=CRawDiskImage ./hfs.main

sudo cp "/Volumes/${RAM_DISK_NAME}/etc/fstab" "/Volumes/${RAM_DISK_NAME}/etc/fstab_orig"

sudo tee "/Volumes/${RAM_DISK_NAME}/etc/fstab" <<EOF
/dev/disk0 / hfs ro 0 1
/dev/disk1 /private/var hfs rw,nosuid,nodev 0 2
EOF

sudo rm "/Volumes/${RAM_DISK_NAME}/System/Library/LaunchDaemons/com.apple.mobile.keybagd.plist"

sudo cp "/Volumes/${RAM_DISK_NAME}/sbin/launchd" ./launchd_unpatched

# patched according to https://github.com/alephsecurity/xnu-qemu-arm64/wiki/Build-iOS-on-QEMU
# patch instruction at 0x10002fb18
# cset w20,ne
# mov w20,#0x01

# Download pre-patched
if [[ "${PATCH_LAUNCHD}" = true ]]; then
    wget "${PATHCED_LAUNCHD}"
    sudo cp -f "$(basename "${PATHCED_LAUNCHD}")" "/Volumes/${RAM_DISK_NAME}/sbin/launchd"
fi

hdiutil detach "/Volumes/${RAM_DISK_NAME}"
hdiutil detach "/Volumes/${IOS_DISK_NAME}"

cp "./${RAM_DISK}.out" ./hfs.sec
hdiutil resize -size 6G -imagekey diskimage-class=CRawDiskImage ./hfs.sec
hdiutil attach -imagekey diskimage-class=CRawDiskImage ./hfs.sec
hdiutil attach "./${IOS_DISK}"

sudo rm -rf "/Volumes/${RAM_DISK_NAME}/"*
sudo rsync -av "/Volumes/${IOS_DISK_NAME}/private/var/"* "/Volumes/${RAM_DISK_NAME}/"

sudo mkdir "/Volumes/${RAM_DISK_NAME}/dropbear"

hdiutil detach "/Volumes/${RAM_DISK_NAME}"
hdiutil detach "/Volumes/${IOS_DISK_NAME}"

# PATCH dyld if you want to use gdb
hdiutil attach -imagekey diskimage-class=CRawDiskImage ./hfs.main
cp "/Volumes/${RAM_DISK_NAME}/usr/lib/dyld" ./dyld_unpatched

# dyld patched according to https://github.com/alephsecurity/xnu-qemu-arm64/wiki/Disable-ASLR-for-dyld_shared_cache-load
# patch instruction at 00022720
# csel x0, xzr, x20, ne
# mov x0, #0x0

# pre-patched
if [[ "${PATCH_DYLD}" = true ]]; then
    wget "${PATCHED_DYLD}"
    sudo cp -f "$(basename "${PATCHED_DYLD}")" "/Volumes/${RAM_DISK_NAME}/usr/lib/dyld"
fi

# SIGN everything that wants a signature and add to static trust cache
>tchashes
>static_tc

# sign the patched launchd, the patched dyld, and the tcp-tunnel
sudo jtool --sign --ent ent.xml --ident com.apple.xpc.launchd --inplace "/Volumes/${RAM_DISK_NAME}/sbin/launchd"
sudo jtool --sign --ent ent.xml --inplace "/Volumes/${RAM_DISK_NAME}/usr/lib/dyld"
sudo jtool --sign --ent ent.xml --inplace "/Volumes/${RAM_DISK_NAME}/bin/tunnel"

# rip out the trust cache hashes and add to your very own static trust cache
sudo jtool --sig --ent "/Volumes/${RAM_DISK_NAME}/sbin/launchd"  | grep CDHash | cut -d' ' -f6 | cut -c 1-40 >> ./tchashes
sudo jtool --sig --ent "/Volumes/${RAM_DISK_NAME}/usr/lib/dyld"  | grep CDHash | cut -d' ' -f6 | cut -c 1-40 >> ./tchashes
sudo jtool --sig --ent "/Volumes/${RAM_DISK_NAME}/bin/tunnel"  | grep CDHash | cut -d' ' -f6 | cut -c 1-40 >> ./tchashes

python xnu-qemu-arm64-tools/bootstrap_scripts/create_trustcache.py tchashes static_tc

hdiutil detach "/Volumes/${RAM_DISK_NAME}"

echo 'FIN; Docker-eyeOS'

scp -P 50922 fullname@localhost:~/static_tc .
scp -P 50922 fullname@localhost:~/tchashes .
scp -P 50922 fullname@localhost:~/hfs.main .
scp -P 50922 fullname@localhost:~/hfs.sec .
