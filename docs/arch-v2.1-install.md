# goal for this install
- btrfs partitionning
- snapshots in grub
- snapper as a snapshot utility

# install prerequisits
- verify internet connection
```
ping -c4 1.1.1.1
```

- system clock
```
timedatectl set-timezone Europe/Paris
```

- update mirrors
```
reflector -c France -a 12 --sort rate --save /etc/pacman.d/mirrorlist
```

- update pacman cache
```
pacman -Syyy
```

- enable ntp
```
timedatectl set-ntp true
```

- upgrade keyring (it can cause problems later)
```
pacman -S archlinux-keyring
```

---
# partitionning
- find your disk
```
fdisk -l 
```
- enter fdisk (or gdisk)
```
fdisk /dev/nvme0n1
```
### partition scheme
- create partition 1:
	- 2GO
	- type : 1 (EFI)
- create partition 2:
	- 4GO
	- type : 19 (SWAP)
- create partition 3:
	- 1000 GO
	- type : 20 (Linux)

### Checkhealth ```
```
Device            Start        End    Sectors   Size Type
/dev/nvme0n1p1     2048    4196351    4194304     2G EFI System
/dev/nvme0n1p2  4196352   12584959    8388608     4G Linux swap
/dev/nvme0n1p3 12584960 1953523711 1940938752 925.5G Linux filesystem
```

---
# formatting
### efi partition
- create FAT32 on partition 1
```
mkfs.fat -F 32 /dev/nvme0n1p1
```

### swap partition
- create swap partition
```
 mkswap /dev/nvme0n1p2
```
- enable the swap
```
swapon /dev/nvme0n1p2
```

### encrypted root partition
- create the encrypted volume
```
cryptsetup luksFormat /dev/nvme0n1p3
```
- open the encrypted volume
```
cryptsetup luksOpen /dev/nvme0n1p3 main
```
- create the BTRFS partition
```
mkfs.btrfs /dev/mapper/main
```

### Checkhealth : 
```
Device            Start        End    Sectors   Size Type
nvme0n1     259:0    0 931.5G  0 disk
├─nvme0n1p1 259:4    0     2G  0 part
├─nvme0n1p2 259:5    0     4G  0 part  [SWAP]
└─nvme0n1p3 259:8    0 925.5G  0 part
  └─main    254:0    0 925.5G  0 crypt
```
---
# btrfs and mounting
- mount the partition3 to `/mnt`
```
mount /dev/mapper/main /mnt
```

- create the subvolumes (root, home, var, snapshots)
```
cd /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
```

- unmount the partition 3
```
umount /mnt
```

- mount the root subvolume to `/mnt`
```
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@ /dev/mapper/main /mnt
```

- create the directories corresponding to the subvolumes
```
mkdir /mnt/{boot,home,var}
```

- mount the remaining subvolumes
```
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@home /dev/mapper/main /mnt/home

mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@var /dev/mapper/main /mnt/var
```

- **don't forget to mount partition 1 on /boot**
```
mount /dev/nvme0n1p1 /mnt/boot
```

- CHECKHEALTH : 
```
NAME     MAJ:MIN RM SIZE RO TYPE  MOUNTPOINTS
vda      254:0    0  25G  0 disk
├─vda1   254:1    0   2G  0 part  /mnt/boot
├─vda2   254:2    0   4G  0 part  [SWAP]
└─vda3   254:3    0  19G  0 part
  └─main 253:0    0  19G  0 crypt /mnt/var
                                  /mnt/home
                                  /mnt
```

---
# Bootstrap the OS
- run the pacstrap command
```
pacstrap /mnt base base-devel linux linux-firmware intel-ucode vim
```

- generate Fstab
```
genfstab -U /mnt >> /mnt/etc/fstab
```

- change root directory
```
arch-chroot /mnt
```
## regional settings
- set the timezone
```
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
```
- sync the hardware clock
```
hwclock --systohc
```

- set the locale by uncommenting en_US.utf-8
```
vim /etc/locale.gen
```
- generate the locale
```
locale-gen
```
- set the LANG variable
```
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

## host settings
- set the hostname
```
echo "archtop" > /etc/hostname
```
- set the /etc/hosts file
```
cat << EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.0.1   archtop.localdomain archtop
EOF
```

- set the /etc/vconsole.conf file
```
cat << EOF > /etc/vconsole.conf
KEYMAP="fr"
FONT="ter-228b"
EOF
```

- change the root password
	- **change the password to a secure one**
```
echo "root:mypassw" | chpasswd
```

- install more packages
```
pacman -S grub-btrfs grub efibootmgr networkmanager timeshift reflector tmux man-db man-pages bash-completion inotify-tools git rsync terminus-font btrfs-progs firewalld --noconfirm
```

- enable NetworkManager
```
systemctl enable NetworkManager
```
- enable Firewalld
```
systemctl enable firewalld
```
- enable fstrim timer
```
systemctl enable fstrim.timer
```
- enable reflector timer
```
systemctl enable reflector.timer
```
---
# Bootloader
- add btrfs module to initramfs
```
vim /etc/mkinitcpio.conf
MODULES=(btrfs)
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)
```
- generate the initramfs
```
mkinitcpio -p linux
```

- install grub
```
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
```
- configure crypt device
```
vim /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet cryptdevice=UUID=<uuid-of-/dev/harddisk>:main root=/dev/mapper/main"
...
GRUB_ENABLE_CRYPTODISK=y
```
- generate grub config
```
grub-mkconfig -o /boot/grub/grub.cfg
```

- **NOTE** : on some hardware, you are required to have a `/boot/EFI/BOOT/bootx64.efi`, and you need to copy `/boot/EFI/GRUB/grubx64.efi` to this destination
## Create user
- create user
```
useradd -mG wheel krem
```
- add sudo privileges
```
visudo
# uncomment `%wheel ALL=(ALL:ALL) ALL`
```
- add a password
	- **change the password to a secure one**
```
echo "krem:krem" | chpasswd
```
## finish install
- detach using `ctrl-D`

- unmount all disks
```
umount -a
```
- reboot
```
reboot
```