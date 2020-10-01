# Docker-eyeOS

Run the iPhone's xnu-qemu-arm64 (iOS) in a Docker container

Supports KVM + GDB kernel debugging! Run armv8-A in a Docker! Works on ANY device!

## [Follow us @sickcodes on Twitter for updates!](https://twitter.com/sickcodes)

### Docker-eyeOS v1.0.12.1
# Features In Docker-eyeOS
- qemu-system-aarch64 boot into iOS!
- Runs on ANY device
- FULL iOS armv8-A GDB Kernel debugging support (step thru & debug the iOS kernel on Linux!)
- X11 Forwarding (future Display)
- SSH on localhost:2222 or container.ip:2222
- GDB on localhost:1234 or container.ip:1234
- QEMU Full xnu-qemu-Virtualization
- Container host Arch

### Author:
- Sick.Codes Team [@sickcodes](https://twitter.com/sickcodes)
- [https://twitter.com/sickcodes](https://twitter.com/sickcodes)
- [https://sick.codes/](https://sick.codes/)
- [https://github.com/sickcodes](https://github.com/sickcodes)

Run iPhone (xnu-arm64) in a Docker container! Supports KVM + iOS kernel debugging (GDB)! Run xnu-qemu-arm64 in Docker! Works on ANY device.

# Dockerhub

[https://hub.docker.com/r/sickcodes/docker-eyeos](https://hub.docker.com/r/sickcodes/docker-eyeos)

```bash

mkdir -p images
cd images

wget https://images.sick.codes/hfs.sec.zst
wget https://images.sick.codes/hfs.main.zst

# decompress images, uses about 15GB
zstd -d hfs.main.zst
zstd -d hfs.sec.zst

docker pull sickcodes/docker-eyeos:latest

docker run -it --privileged \
    --device /dev/kvm \
    -e RAM=6 \
    -e HFS_MAIN=./images/hfs.main \
    -e HFS_SEC=./images/hfs.sec \
    -p 2222:2222 \
    -v "$PWD:/home/arch/docker-eyeos/images" \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    sickcodes/docker-eyeos:latest


ssh root@localhost -p 2222

# -----> Try to SSH about 4 times
# -----> also needs to HIT ENTER a few times in the terminal to kick it along


```

## NOTE:

- Hit enter a few times in the container terminal until you see `-bash-4.4#`

- SSH into the container on `localhost:2222` or `containerIP:2222`


# RUN Docker-eyeOS with GDB iOS Kernel Debugging!

```bash

docker run -it --privileged \
    --device /dev/kvm \
    -e RAM=6 \
    -e HFS_MAIN=./images/hfs.main \
    -e HFS_SEC=./images/hfs.sec \
    -p 2222:2222 \
    -v "$PWD:/home/arch/docker-eyeos/images" \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -p 1233:1234 \
    -e GDB_ARGS='-S -s' \
    docker-eyeos:latest
    sickcodes/docker-eyeos:latest

# image will halt

# get container ID
docker ps
docker exec -it 3cb2d14fc11a /bin/bash -c "cd /home/arch/docker-eyeos/xnu-qemu-arm64-tools/gdb; gdb-multiarch -q"

# run 
source load.py
target remote localhost:1234


```


### Export PATH

```bash
# once you have SSH'ed in, export PATH and look busy!
export PATH=/iosbinpack64/usr/bin:/iosbinpack64/bin:/iosbinpack64/usr/sbin:/iosbinpack64/sbin:$PATH

```

### How do I mount the disk and put stuff in there?

```bash
sudo losetup -f 
sudo losetup /dev/loop0 ./hfs.main

# mount in a file manager

# unmount and delete loop device when done
sudo losetup -d /dev/loop0
```

# Upstream Projects

- [xnu-qemu-arm64](https://github.com/alephsecurity/xnu-qemu-arm64) a.k.a the guts of this project
- [xnu-qemu-arm64-tools](https://github.com/alephsecurity/xnu-qemu-arm64-tools)

# Upstream Masterminds
Supported by:

- Aleph Security [@AlephSecurity](https://alephsecurity.com/)
- Vera Mens [@v3rochka GitHub](https://github.com/V3rochka) && [@v3rochka Twitter](https://twitter.com/V3rochka)
- Jonathan Afek [@jonyafek GitHub](https://github.com/jonyafek) && [@JonathanAfek Twitter](https://twitter.com/JonathanAfek)
- Lev Aronsky [@aronsky GitHub](https://github.com/aronsky) && [@levaronsky Twitter](https://twitter.com/levaronsky)

TCP Tunnel for Linux rework:

- MCApollo [@MCApollo GitHub](https://github.com/MCApollo/)

# Requirements

- 20GB++ of Disk Space
- QEMU
- KVM

# GDB Debugging

```bash

# run Docker-eyeOS with
-e GDB_ARGS='-S -s' \

# get container id
docker ps

# run gdb-multiarch
docker exec containerid /bin/bash -c "cd /home/arch/docker-eyeos/xnu-qemu-arm64-tools/gdb; gdb-multiarch -q"

# run 
source load.py
target remote localhost:1234

```


Run outside the container
```bash
# Ubuntu, Debian, Pop!_OS
sudo apt install gdb-multiarch
# Arch, Majaro
sudo pacman -S gdb-multiarch
```

```bash
git clone https://github.com/alephsecurity/xnu-qemu-arm64-tools.git
cd ./xnu-qemu-arm64-tools/gdb
sudo gdb-multiarch -q
source load.py
target remote localhost:1234
```



# Coming Soon   

- ARCH: xnu-qemu-arm64 for iOS 14
- ETA: son, follow [@sickcodes](https://twitter.com/sickcodes) && [@sickcodes](https://twitter.com/sickcodes)

# Supported

## KVM

### Requires a device that supports armv8-A

See [https://alephsecurity.com/2020/07/19/xnu-qemu-kvm/](https://alephsecurity.com/2020/07/19/xnu-qemu-kvm/)

```bash
# proposed docker env command line args when KVM 
    -e KVM=true
    -e KVM=false

```

# What does it do?

Docker-eyeOS is an exploration platform for researchers and anyone who is interested in the XNU kernel.

# Images

- Create your own using [Docker-OSX](https://github.com/sickcodes/Docker-OSX) 
- And then run `osx-build-xnu-disks.sh` shell script.

```bash
# compress images for any reason
zstd -k hfs.main
zstd -k hfs.sec

# decompress images
zstd -d hfs.main.zst
zstd -d hfs.sec.zst

# after you decompress HFS Plus images, you must fsck them until they are OK using hfsprogs.

fsck.hfsplus -fp ./hfs.sec
fsck.hfsplus -fp ./hfs.sec
fsck.hfsplus -fp ./hfs.main
fsck.hfsplus -fp ./hfs.main

```

# Optional Flags

Download pre-patched image -
- WARNING 1.8GB of disks are downloaded
- Expands to 12GB of disks uncompressed

`-e GDB_PORT=1234`

Default is already set to 1234, feel free to change it

`-e GDB=true`

Enables GDB (QEMU will be interrupted until GDB starts)

# Unpatched Version

- Alternatively, you can create your own disks as abov

- If you do not wish to patch `dyld` then you should include all 4 files in your images folder:

`./hfs.main`

`./hfs.sec`

`./static_tc`

`./tchashes`


# To Do (Help Wanted)

### Ad hoc images

`-e STORAGE=host`

Store the images in ./images on the host folder

`-e STORAGE=guest`

Store the images in a local folder inside the container (Watch out for disk space usage if doing this)


### VNC

```bash
mkdir screendump
cd screendump
wget https://github.com/cosmosgenius/screendump/releases/download/0.0.3/com.cosmosgenius.screendump_0.0.3_iphoneos-arm.deb
sudo pacman -S wget
wget https://github.com/cosmosgenius/screendump/releases/download/0.0.3/com.cosmosgenius.screendump_0.0.3_iphoneos-arm.deb
ar -x com.cosmosgenius.screendump_0.0.3_iphoneos-arm.deb
tar -xzvf data.tar.lzma
# mount and put in the disk
```

### Solve outbound networking
```bash

bash -i >& /dev/tcp/google.com/80 0>&1          # requires DNS
bash -i >& /dev/tcp/172.217.22.142/80 0>&1      # perhaps -netdev

```

# How to build your own hfs.main and hfs.sec disk on GNU/Linux for Docker-eyeOS

Note: this process can take around 1-4 hours depending on your specs.

- Use OSX or create a quick OSX-KVM using [Docker-OSX](https://github.com/sickcodes/Docker-OSX)

```bash
# this is Docker-OSX btw
docker run --device /dev/kvm \
--device /dev/snd \
-e RAM=12 \
-p 50922:10022 \
-v /tmp/.X11-unix:/tmp/.X11-unix \
sickcodes/docker-osx:latest
```

- Complete the graphical installation, guide here: [https://github.com/sickcodes/Docker-OSX#additional-boot-instructions](https://github.com/sickcodes/Docker-OSX#additional-boot-instructions)

- Turn on SSH in `Sharing Settings`

- Write down your docker container ID with `docker ps`, e.g. `f771bff2192d`
-- You can start the docker later using `docker run f771bff2192d`
-- You don't need to login to SSH into the Docker-OSX

- SSH into your [Docker-OSX](https://github.com/sickcodes/Docker-OSX) and add yourself as a NOPASSWD root user (extremely insecure, only do if you will tear-down later).

```bash

# OPTIONAL SPEED UP
ssh fullname@localhost -p 50922

sudo tee "/private/etc/sudoers.d/sudoers_$USER" <<EOF
${USER} ALL = (ALL) NOPASSWD: ALL
EOF

```

- Complete the script on OSX that is inside this repo
- Pull the images out

```bash

scp -P 50922 fullname@localhost:~/static_tc .
scp -P 50922 fullname@localhost:~/tchashes .
scp -P 50922 fullname@localhost:~/hfs.main .
scp -P 50922 fullname@localhost:~/hfs.sec .

```

Enjoy!

# <3 Sick.Codes(https://sick.codes)



