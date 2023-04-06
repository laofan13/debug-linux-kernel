LINUX-SOURCE 	:= ./linux-5.4.228
BUSYBOX-SOURCE	:= ./busybox-1.35.0
LINUX-KERNEL 	:= $(LINUX-SOURCE)/arch/x86_64/boot/bzImage
LINUX-INITRD 	:= $(BUSYBOX-SOURCE)/initramfs.cpio.gz

QEMU := qemu-system-x86_64

QEMU-OPTIONS-NORMAL := \
	-m 512M \
	-smp 1

QEMU-OPTIONS-ACCELERATION := \
	-machine q35

QEMU-OPTIONS-NERWORK := \
	-net nic -net user

QEMU-OPTIONS-GRAPHIC := \
	-nographic \
	-serial mon:stdio

QEMU-OPTIONS-LINUX-APPEND := \
	-append "rdinit=/linuxrc nokaslr console=ttyS0 loglevel=8"

QEMU-OPTIONS-LINUX-KERNEL-INITRD := \
	-kernel $(LINUX-KERNEL) \
	-initrd $(LINUX-INITRD)


QEMU-OPTIONS-LINUX-START := \
	$(QEMU-OPTIONS-NORMAL) \
	$(QEMU-OPTIONS-ACCELERATION) \
	$(QEMU-OPTIONS-NERWORK) \
	$(QEMU-OPTIONS-GRAPHIC) \
	$(QEMU-OPTIONS-LINUX-APPEND) \
	$(QEMU-OPTIONS-LINUX-KERNEL-INITRD)

QEMU-OPTIONS-DEBUG := -s -S

all:qemu

#run linux
qemu:
	$(QEMU) $(QEMU-OPTIONS-LINUX-START) 

# debugging linux
qemu-gdb: 
	$(QEMU) $(QEMU-OPTIONS-LINUX-START) $(QEMU-OPTIONS-DEBUG)
