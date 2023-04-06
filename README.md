# Install the build toolchain
```sh
sudo apt-get install libncurses5-dev  build-essential git bison flex libssl-dev
```
## compile the kernel

### 1. download linux source
```sh
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.129.tar.xz
cd linux-5.10.129
```

### 2. configure the kernel
```sh
make defconfig ARCH=x86_64
./scripts/config -e DEBUG_INFO -e DEBUG_KERNEL -e DEBUG_INFO_DWARF4
```

### 3. complie the kernel
```sh
make ARCH=x86_64 Image
# make ARCH=arm64 Image -j8  CROSS_COMPILE=aarch64-linux-gnu-
```

# make root file system using busybox
linux的启动需要配合根文件系统，这里我们利用busybox来制作一个简单的根文件系统

## Compile busybox

### 1. download busybox
```sh
wget https://busybox.net/downloads/busybox-1.35.0.tar.bz2
tar -xjf busybox-1.35.0.tar.bz2
cd busybox-1.35.0
```
### 2. config busybox
```sh
make defconfig ARCH=x86_64
Settings --->
 [*] Build static binary (no shared libs) 
```

### 3. Specify the arch and cross-toolchain
```sh
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
```

### 4. complie busybox
After the compilation is completed, the _install directory is generated in the busybox directory
```sh
make && make install
```

## custom file system

### 1. Add etc, dev and lib directories
```sh
cd _install
mkdir etc dev lib mnt
```

### 2. etc/profile
busybox 作为linuxrc启动后， 会读取/etc/profile, 这里面设置了一些环境变量和shell的属性
```sh
#!/bin/sh
export HOSTNAME=lifan
export USER=root
export HOME=/home
export PS1="[$USER@$HOSTNAME \W]\# "
PATH=/bin:/sbin:/usr/bin:/usr/sbin
LD_LIBRARY_PATH=/lib:/usr/lib:$LD_LIBRARY_PATH
export PATH LD_LIBRARY_PATH
```

### 3. etc/inittab
```sh
#!/bin/sh
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
::askfirst:-/bin/sh
::ctrlaltdel:/bin/umount -a -r
```
### 4. etc/fstab
```sh
#device  mount-point    type     options   dump   fsck order
proc /proc proc defaults 0 0
tmpfs /tmp tmpfs defaults 0 0
sysfs /sys sysfs defaults 0 0
tmpfs /dev tmpfs defaults 0 0
debugfs /sys/kernel/debug debugfs defaults 0 0
kmod_mount /mnt 9p trans=virtio 0 0
```
### 5. etc/init.d/rcS
```sh
mkdir -p /sys
mkdir -p /tmp
mkdir -p /proc
mkdir -p /mnt
/bin/mount -a
mkdir -p /dev/pts
mount -t devpts devpts /dev/pts
echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s
```

#### update permissions
```sh
chmod +x etc/init.d/rcS
```

### 6. Add dev file 
```sh
sudo mknod console c 5 1
sudo mknod -m 666 null c 1 3 
```

### 7. Add dynamic library
```sh
cp /usr/lib/gcc/x86_64-linux-gnu/9/*.so*  -a ./lib
```

### 8.compressed file system
```sh
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
```

这里对这几个文件做一点说明：
1. busybox 作为linuxrc启动后， 会读取/etc/profile, 这里面设置了一些环境变量和shell的属性
2. 根据/etc/fstab提供的挂载信息， 进行文件系统的挂载
3. busybox会从/etc/inittab中读取sysinit并执行， 这里sysinit指向了/etc/init.d/rcS
4. /etc/init.d/rcS 中 ，mdev -s 这条命令很重要， 它会扫描/sys目录，查找字符设备和块设备，并在/dev下mknod
