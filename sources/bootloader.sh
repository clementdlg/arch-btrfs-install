ramfs() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	file="/etc/mkinitcpio.conf"

	# MODULES
	if arch "grep '^MODULES=(.*)$' $file" ; then
		arch "sed -i 's/^MODULES=(.*)$/MODULES=(btrfs)/' $file"
	else
		arch "echo 'MODULES=(btrfs)'" >> $file
	fi

	# HOOKS
	hook="HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)"

	if arch "grep '^HOOKS=(.*)' $file" ; then
		arch "sed -i \"s/^HOOKS=(.*)$/${hook}/\" $file"
	else
		arch "echo \"$hook\" >> $file"
	fi

	arch "mkinitcpio -p linux"

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

grub_install() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	target="x86_64-efi"
	efi="/boot"
	id="GRUB"

	if [[ ! -d "/mnt$efi" ]]; then
		log e "/mnt$efi is not a valid directory"
		return 1
	fi

	arch "grub-install --target=$target \
		--efi-directory=$efi \
		--bootloader-id=$id"

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

grub_cfg() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	file="/etc/default/grub"
	linux=$(fdisk -x ${_MAIN_DISK} | grep 'LINUX' | cut -d' ' -f1)

	uuid=$(blkid "$linux" \
		| cut -d' ' -f2 \
		| cut -d\" -f2)


	key="GRUB_CMDLINE_LINUX_DEFAULT"
	value="loglevel=3 quiet cryptdevice=UUID=$uuid:main root=/dev/mapper/main"

	pattern="^$key=\".*\"$"
	replace="$key=\"$value\""

	if arch "grep '$pattern' $file" ; then
		arch "sed -i 's|$pattern|$replace|' $file"
	else
		arch "echo '$replace' >> $file"
	fi
	
	grub_conf="/boot/grub/grub.cfg"
	arch "grub-mkconfig -o $grub_conf"

	# create default entree
	source="/mnt/boot/EFI/GRUB/grubx64.efi"
	destination="/mnt/boot/EFI/BOOT"
	file="BOOTx64.EFI"
	mkdir -p "$destination"
	cp "$source" "$destination/$file"

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

