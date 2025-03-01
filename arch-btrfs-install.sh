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
}

silent() {
	"$@" &>/dev/null
}

log() {
	trap "$trap_msg" ERR
	echo "[INFO] $1" | tee -a "$LOG_FILE"
}

source_files() {
	trap "$trap_msg" ERR

	path="sources"
	[[ -d "$path" ]]

	for file in "$path"/*; do
		[[ -f "$file" ]]
		source "$file"
	done
}

source_config() {
	trap "$trap_msg" ERR

	local config="arch-btrfs-install.conf"

	source "$config"
}


main() {
	trap "$trap_msg" ERR

	source_files

	# prerequisits
	source_config
	verify_config_keys
	check_boot_mode
	check_connection
	set_time
	display_warning

	# disks
	partitionning_disk
	formatting_disk
	mount_fs

	# bootstrap

}

main "$@"
