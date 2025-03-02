#!/usr/bin/env bash
set -xeuo pipefail

arch() {
	arch-chroot /mnt "$@"
}

ramfs() {
	# trap "$trap_msg" ERR
	file="/etc/mkinitcpio.conf"

	# MODULES
	if [[ -z "$(arch grep '^MODULES=(.*)$' $file)" ]]; then
		arch echo "MODULES=(btrfs)" >> $file
	else
		arch sed -i 's/^MODULES=(.*)$/MODULES=(btrfs)/' $file
	fi

	# HOOKS
	hook="HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)"

	if [[ -z "$(arch grep "^HOOKS=(.*)" $file)" ]]; then
		arch echo "$hook" >> $file
	else
		arch sed -i "s/^HOOKS=(.*)$/$hook/" $file
	fi

	arch mkinitcpio -p linux
}

grub_install() {
	# trap "$trap_msg" ERR
	target="x86_64-efi"
	efi="/boot"
	id="GRUB"

	arch grub-install --target="$target" \
		--efi-directory="$efi" \
		--bootloader-id="$id"
}

grub_cfg() {
	file="/etc/default/grub"

	uuid=$(blkid /dev/vda \
		| cut -d' ' -f2 \
		| cut -d\" -f2)


	key="GRUB_CMDLINE_LINUX_DEFAULT"
	value="loglevel=3 quiet cryptdevice=UUID=$uuid:main\ root=/dev/mapper/main"

	if [[ ! -z "$(arch grep "^$key=\".*\"$" $file)" ]]; then
		arch sed -i "s/^$key=.*$//" $file
	fi
	arch echo "$key=\"$value\"" >> $file
	
	key="GRUB_ENABLE_CRYPTODISK"
	value="y"

	if [[ ! -z "$(arch grep "^$key=.$" $file)" ]]; then
		arch sed -i "s/^$key=.$/$key=$value/" $file
	else
		arch echo "$key='$value'" >> $file
	fi

	arch grub-mkconfig -o /boot/grub/grub.cfg
}

