# arch-btrfs-install

## WARNING : this is a work in progress

## Documentation
- I wrote this documentation to help me write this tool, 
- this is basically the relevant arch wiki articles put together in the appropriate order
- Configuration documentation (forthcoming)
- Install : [here](docs/arch-v2.1-install.md)
- Post Install : [here](docs/arch-v2.1-postinstall.md)


## How to use ?
- Bootup on the arch ISO, found it [here](https://archlinux.org/download/)
- run this command
```bash
git clone https://github.com/clementdlg/arch-btrfs-install
```

- Edit the configuration file
```bash
nano arch-btrfs-install.conf
```

- Run the script :
```bash
chmod +x arch-btrfs-install.sh
./arch-btrfs-install.sh
```

## Component used
- [LUKS](https://en.wikipedia.org/wiki/Linux_Unified_Key_Setup) : disk encryption
- [BTRFS](https://btrfs.readthedocs.io/en/latest/Introduction.html) : advanced filesystem
- [GRUB-BTRFS](https://github.com/Antynea/grub-btrfs) : GRUB entries for snapshots
- [TIMESHIFT](https://github.com/linuxmint/timeshift) : snapshot utility
- [TIMESHIFT-AUTOSNAP](https://aur.archlinux.org/packages/timeshift-autosnap) : pacman hook
