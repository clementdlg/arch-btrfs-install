#!/usr/bin/env bash

# Exit on failure
set -xeuo pipefail

trap_msg='echo "[EXIT] failed at '\${FUNCNAME[0]}' "; cleanup /dev/mapper/main;'

cleanup() {
	if lsblk | awk '{ print $7 }' | grep '/mnt'; then
		echo "[CLEANUP] Unmounting LINUX..."  
		umount -R /mnt
	fi

	echo "[CLEANUP] Closing CRYPT-FS..."  
	cryptsetup luksClose $1

	# echo "[END] ARCH-INSTALL has failed. Chech the logs at ${WORKDIR}"  
}

silent() {
	"$@" &>/dev/null
}

log() {
	trap "$trap_msg" ERR
	echo "[INFO] $1" | tee -a "$LOG_FILE"
}

source_files() {

	path="sources"
	[[ -d "$path" ]]

	for file in "$path"/* ; do
		[[ -f "$file" && "$file" == *".sh" ]]
		source "$file"
	done
}

source_config() {
	trap "$trap_msg" ERR

	local config="arch-btrfs-install.conf"

	source "$config"
}

arch() {
	arch-chroot /mnt bash -c "$@"
}

main() {
	trap "$trap_msg" ERR

	source_files

	# Prerequisits
	source_config
	verify_config_keys
	display_warning
	check_boot_mode
	check_connection
	set_time
	update_repos

	# Disks
	partitionning_disk
	formatting_disk
	mount_fs

	# Os settings
	bootstrap
	set_locale
	host_settings
	install_system_utils
	systemd_services
	add_user

	# Bootloader
	ramfs
	grub_install
	grub_cfg

	# finish
	# umount -R /mnt
	# reboot

}

main "$@"
