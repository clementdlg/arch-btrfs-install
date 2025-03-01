#!/usr/bin/env bash

# Exit on failure
set -xeuo pipefail

# trap_msg='echo "[EXIT] failed at '\${FUNCNAME[0]}' "; cleanup;'
# trap "$trap_msg" ERR

cleanup() {
	echo "[CLEANUP] Unmounting LINUX..."  
	cryptsetup luksClose $1
}

silent() {
	"$@" &>/dev/null
}

log() {
	echo "[INFO] $1" | tee -a "$LOG_FILE"
}

source_files() {
	trap 'echo "[EXIT] failed at '\${FUNCNAME[0]}' "; cleanup;' ERR

	path="sources"
	[[ -d "$path" ]]

	for file in "$path"/*; do
		[[ -f "$file" ]]
		source "$file"
	done
}

source_config() {
	trap 'echo "[EXIT] failed at '${FUNCNAME[0]}' "; cleanup;' ERR

	local config="arch-btrfs-install.conf"

	source "$config"
}


main() {
	trap 'echo "[EXIT] failed at '${FUNCNAME[0]}' "; cleanup;' ERR

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
