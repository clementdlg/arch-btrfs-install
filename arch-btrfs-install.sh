#!/usr/bin/env bash

# The script will exit at the first failure
set -euo pipefail

# used for loging
green="\e[32m"
yellow="\e[33m"
red="\e[31m"
purple="\033[95m"
reset="\e[0m"

# This will be executed upon failure 
trap_msg='log e "$red[LINE $LINENO][FUNCTION ${FUNCNAME[0]}]$reset \
Failed to execute : <'\$BASH_COMMAND'>" \
;  cleanup /dev/mapper/main;'

# public functions
source_files() {
	trap "$trap_msg" ERR

	path="sources"
	[[ -d "$path" ]]

	source "$path/prerequisits.sh" || false
	source "$path/disks.sh" || false
	source "$path/bootstrap.sh" || false
	source "$path/bootloader.sh" || false

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
	check_state "${FUNCNAME[0]}" && return

	mkdir -p "$_WORKING_DIR" # create directory

	# create/overwrite log files
	echo "" > "$_LOGFILE"
	echo "" > "$_WORKING_DIR/$_STATE_FILE"

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

arch() {
	silent arch-chroot /mnt bash -c "$@"
}

log() {
	msg="$2"
	[[ ! -z "$msg" ]]

	timestamp="[$(date +%H:%M:%S)]"

	label=""
	case "$1" in
		c) label="[CLEANUP]" ; color="$yellow" ;;
		e) label="[ERROR]" ; color="$red" ;;
		x) label="[EXIT]" ; color="$yellow" ;;
		d) label="[DEBUG]" ; color="$purple" ;;
		i) label="[INFO]" ; color="$green" ;;
	esac

	log="$timestamp$color$label$reset $msg "
	echo -e "$log"

	log="$timestamp$label $msg "

	[[ ! -f ${_LOGFILE} ]] && return
	echo "$log" >> ${_LOGFILE}
}

check_state() {
	trap "$trap_msg" ERR

	fstate="$_WORKING_DIR/$_STATE_FILE"
	func_name="$1"

	[[ -f "$fstate" ]] || return 1

	grep "$func_name" "$fstate" || return 1

	log i "Recovered state for $func_name, skipping"
	return 0

}

update_state() {
	trap "$trap_msg" ERR

	fstate="$_WORKING_DIR/$_STATE_FILE"
	func_name="$1"

	[[ -f "$fstate" ]] || return 1

	echo "$func_name" >> "$fstate"
}


cleanup() {
	# implement a way to make shure we reformat the disk if pacstrap failed
	# if ... something; then
	# 	log c "pacstrap failed : wiping disk"
	# 	wipefs ...
	# fi
	
	if lsblk | awk '{ print $7 }' | silent grep '/mnt'; then
		log c "Unmounting partitions"
		silent umount -R /mnt
	fi

	if lsblk | silent grep crypt ; then
		log c "Closing CRYPT-FS"
		silent cryptsetup luksClose "$1"
	fi

	log x "ARCH-INSTALL has failed safely. Chech the logs at ${_LOGFILE}"  
	exit
}

# hello() {
# 	trap "$trap_msg" ERR
# 	check_state "${FUNCNAME[0]}" && return
#
# 	log i "Hello world!"
#
# 	update_state "${FUNCNAME[0]}" 
# 	log i "${FUNCNAME[0]} : success"
# }

main() {
	trap "$trap_msg" ERR

	# global functions
	source_config
	source_files
	create_workdir

	# Prerequisits
	verify_config_keys
	check_connection
	check_boot_mode
	set_time
	update_repos

	# Disks
	partitionning_disk
	formatting_disk
	create_btrfs_subvolumes
	mount_fs

	# Os settings
	bootstrap
	set_locale
	host_settings
	install_system_utils
	add_user
	false # exit script

	# Bootloader
	ramfs
	grub_install
	grub_cfg

	# finish
	umount -R /mnt
	reboot
	rm -r "${_WORKDIR}"

}

main "$@"
