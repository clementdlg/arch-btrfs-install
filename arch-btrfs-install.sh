#!/usr/bin/env bash

# Exit on failure
set -euo pipefail

trap_msg='log e "Failed command : <'\$BASH_COMMAND'>"; log e "Failed function : '\${FUNCNAME[0]}'";  cleanup /dev/mapper/main;'

source_files() {
	trap "$trap_msg" ERR

	path="sources"
	[[ -d "$path" ]]

	source "$path/prerequisits.sh"
	source "$path/disks.sh"
	source "$path/bootstrap.sh"
	source "$path/bootloader.sh"

	log i "${FUNCNAME[0]} : success"
}

source_config() {
	trap "$trap_msg" ERR

	local config="arch-btrfs-install.conf"
	source "$config"

	log i "${FUNCNAME[0]} : success"
}

silent() {
	"$@" >/dev/null
}

create_workdir() {
	trap "$trap_msg" ERR

	mkdir -p "$_WORKING_DIR"
	echo "# arch-btrfs-install run of $(date)" > ${_LOGFILE}

	log i "${FUNCNAME[0]} : success"
}

arch() {
	arch-chroot /mnt bash -c "$@"
}

log() {
	trap "$trap_msg" ERR

	color="\e[32m"
	yellow="\e[33m"
	red="\e[31m"
	reset="\e[0m"

	msg="$2"
	[[ ! -z "$msg" ]]

	timestamp="[$(date +%H:%M:%S)]"

	label="[INFO]"
	case "$1" in
		c) label="[CLEANUP]" ; color="$yellow" ;;
		e) label="[ERROR]" ; color="$red" ;;
		x) label="[EXIT]" ; color="$yellow" ;;
	esac

	log="$timestamp$color$label$reset $msg "
	echo -e "$log"

	log="$timestamp$label $msg "
	echo "$log" >> ${_LOGFILE}
}

cleanup() {
	set +eu
	if lsblk | awk '{ print $7 }' | grep '/mnt'; then
		log c "Unmounting partitions"
		umount -R /mnt
	fi

	if lsblk | silent grep crypt ; then
		log c "Closing CRYPT-FS"
		cryptsetup luksClose "$1"
	fi

	log x "ARCH-INSTALL has failed safely. Chech the logs at ${_LOGFILE}"  
	exit
}


main() {
	trap "$trap_msg" ERR

	# global functions
	source_config
	source_files
	create_workdir

	# Prerequisits
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
	mkdir /no/such/file/or/directory

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
