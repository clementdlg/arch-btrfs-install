# Configure grub-btrfsd
- change the unit file
```
sudo systemctl edit --full grub-btrfsd
...
ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto
```
- enable grub-btrfsd
```
systemctl enable --now grub-btrfsd
```

---
# test grub-btrfs
- create a snapshot
```
timeshift --create --comments "after install" --tags D
```
- list snapshots
```
timeshift --list-snapshots --snapshot-device /dev/mapper/main
```
- verify that the `grub.cfg` includes the grub-btrfs submenu
```
tail /boot/grub/grub.cfg

### BEGIN /etc/grub.d/41_snapshots-btrfs ###
if [ ! -e "${prefix}/grub-btrfs.cfg" ]; then
echo ""
else
submenu 'Arch Linux snapshots' {
    configfile "${prefix}/grub-btrfs.cfg"
}
fi
```
- verify that the menuentry of the snapshot has been added
```
grep 'menuentry' /boot/grub/grub-btrfs.cfg
```

---
# install the pacman-hook
## install AUR helper
- clone the paru repo
```
git clone https://aur.archlinux.org/paru.git
cd paru/
```
- install the package
```
makepkg -sic
```

## install AUR package
- install the package
```
paru -S timeshift-autosnap
```
## Configure timeshift-autosnap
- configure the snapshots policy
```
vim /etc/timeshift-autosnap.conf

maxSnapshots=15

updateGrub=false # avoid conflicts with grub-btrfs
```

## Edit the hook
- add support for snapshots on install and removal of packages
```
vim /usr/share/libalpm/hooks/00-timeshift-autosnap.hook
```
- this content :
```
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Creating Timeshift snapshot before transaction...
Depends = timeshift
When = PreTransaction
Exec = /usr/bin/timeshift-autosnap
AbortOnFail
```
---
# add the /boot hook
- the /boot is not btrfs but FAT32 so we use a hook
- the hook triggers a rsync backup from /boot to /.bootbackup
- the hook are found [here](https://wiki.archlinux.org/title/System_backup#Snapshots_and_/boot_partition)
- edit these files
```
vim /usr/share/libalpm/hooks/55-bootbackup_pre.hook
```

```
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz

[Action]
Depends = rsync
Description = Backing up pre /boot...
When = PreTransaction
Exec = /usr/bin/bash -c 'rsync -a --mkpath --delete /boot/ "/.bootbackup/$(date +%Y_%m_%d_%H.%M.%S)_pre"/'
```
