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
trap_msg='log e "$red[LINE $LINENO][FUNCTION ${FUNCNAME[0]}]$reset Failed to execute : <'\$BASH_COMMAND'>"; cleanup'

# public functions
source_files() {
	trap "$trap_msg" ERR

	path="sources"
	[[ -d "$path" ]]

	source "$path/prerequisits.sh" || false
	source "$path/disks.sh" || false
	source "$path/bootstrap.sh" || false
	source "$path/bootloader.sh" || false
	source "$path/success.sh" || false

	log i "${FUNCNAME[0]} : success"
}

source_config() {
	trap "$trap_msg" ERR

	local config="arch-btrfs-install.conf"
	source "$config"

	log i "${FUNCNAME[0]} : success"
}

silent() {
	"$@" >/dev/null || return 1
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
	silent arch-chroot /mnt bash -c "$@" || return 1
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

	if [[ -f ${_LOGFILE} ]]; then
		echo "$log" >> ${_LOGFILE}
	fi
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

	[[ -f "$fstate" ]] || return 0

	echo "$func_name" >> "$fstate"
}


cleanup() {

	log d "Entering cleanup function"

	state="${_WORKING_DIR}/${_STATE_FILE}"
	# if pacstrap has failed, reformat the disk to avoid errors
	last_state="before_pacstrap"
	if tail -1 "$state" | silent grep "$last_state"; then
		log c "Editing system state for recover"
		silent sed -i '/formatting_disk/d' "$state"
		silent sed -i '/create_btrfs_subvolumes/d' "$state"
	fi

	
	if lsblk | awk '{ print $7 }' | silent grep '/mnt'; then
		log c "Unmounting partitions"
		silent umount -R /mnt
	fi

	if lsblk | silent grep crypt ; then
		log c "Closing CRYPT-FS"
		silent cryptsetup luksClose /dev/mapper/main
	fi

	log x "ARCH-INSTALL has exited safely. Chech the logs at ${_LOGFILE}"  
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
	before_pacstrap
	bootstrap
	set_locale
	host_settings
	install_system_utils
	add_user


	# Bootloader
	ramfs
	grub_install
	grub_cfg

	# finish
	enable_post_install
	safe_reboot

}

if [[ -z "$@" ]]; then
	main
elif [[ "$1" == "--task" && ! -z "$2" ]]; then

	source_config
	source_files
	"$2"
fi
