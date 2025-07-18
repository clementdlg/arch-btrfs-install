#!/usr/bin/env bash

# BTRFS subvolumes
subvols=(
	"@"
	"@home"
	"@var_log"
	"@var_spool"
	"@var_cache"
	"@var_tmp"
	"@var_lib_libvirt"
	"@var_lib_docker"
)

# mountpoints for BTRFS subvolumes
mountpoints=(
	""
	"/home"
	"/var/log"
	"/var/spool"
	"/var/cache"
	"/var/tmp"
	"/var/lib/libvirt"
	"/var/lib/docker"
)

# arrays must be the same size
[[ "${#subvols[@]}" == "${#mountpoints[@]}" ]]


disk_part_util() {
	trap "$trap_msg" ERR
	silent sgdisk -n$1::"$2" \
			-t$1:"$3" \
			-c$1:"$4" \
			${_MAIN_DISK}
}

display_warning() {
	trap "$trap_msg" ERR

	prompt="[PROMPT] Are you sure you want to proceed?"

	echo "###############################################"
	echo "####                                       ####"
	echo "####    YOU ARE ABOUT TO WIPE YOUR DISK    ####"
	echo "####                                       ####"
	echo "###############################################"
	printf "\n"

	fdisk -l /dev/vda
	printf "\n\n"

	log i "YOU ARE ABOUT TO WIPE OUT $_MAIN_DISK"
	printf "\n"

	read -p "$prompt ('YES/n'): " response
	if [[ ! "$response" == "YES" ]]; then
		log i "You did NOT wipe ${_MAIN_DISK}"
		cleanup
	fi
}

partitionning_disk() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	if [[ ! -b "$_MAIN_DISK" ]]; then
		log e "Disk $_MAIN_DISK does not exist"
		false
	fi

	# Wipe disk
	silent sgdisk -o ${_MAIN_DISK}

	# partitions ; num; size; type; name
	disk_part_util   1   +2G "EF00" "ESP"
	disk_part_util   2   +4G "8200" "SWAP"
	disk_part_util   3    "" "8300" "LINUX"

	silent sgdisk -p $_MAIN_DISK

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

formatting_disk() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	# TODO : Replace this with global variables
	esp=$(fdisk -x ${_MAIN_DISK} | grep 'ESP' | cut -d' ' -f1)
	swap=$(fdisk -x ${_MAIN_DISK} | grep 'SWAP' | cut -d' ' -f1)
	linux=$(fdisk -x ${_MAIN_DISK} | grep 'LINUX' | cut -d' ' -f1)

	silent mkfs.fat -F 32 $esp # create boot partition

	silent mkswap $swap 2>/dev/null # create swap partition
	swapon $swap # enable swap partition

	echo -n "$_CRYPT_PASSPHRASE" | silent cryptsetup luksFormat -d /dev/stdin $linux
	echo -n "$_CRYPT_PASSPHRASE" | silent cryptsetup luksOpen -d /dev/stdin $linux main

	silent mkfs.btrfs /dev/mapper/main

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

mount_btrfs() {
	trap "$trap_msg" ERR

	subvol="$1"
	mountpoint="$2"
	args="noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol="

	silent mount --mkdir -o "$args$subvol" \
		/dev/mapper/main \
		"/mnt$mountpoint"
}

mount_fs() {
	trap "$trap_msg" ERR

	# TODO : Replace this with global variables
	esp=$(fdisk -x ${_MAIN_DISK} | grep 'ESP' | cut -d' ' -f1)
	linux=$(fdisk -x ${_MAIN_DISK} | grep 'LINUX' | cut -d' ' -f1)

	# ensure mountpoint is clean
	if mount | silent grep /mnt; then
		silent umount -R /mnt
	fi

	# open the LUKS device if needed
	if ! silent cryptsetup status /dev/mapper/main; then
		echo -n "$_CRYPT_PASSPHRASE" | silent cryptsetup luksOpen -d /dev/stdin $linux main
	fi

	# mount each subvolume
	for i in "${!mountpoints[@]}"; do
		mount_btrfs "${subvols[$i]}" "${mountpoints[$i]}"
	done

	silent mount --mkdir "$esp" /mnt/boot

	# avoid duplicates in system.state
	if ! check_state "${FUNCNAME[0]}"; then
		update_state "${FUNCNAME[0]}" 
	fi
	log i "${FUNCNAME[0]} : success"
}

create_btrfs_subvolumes() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	linux=$(fdisk -x ${_MAIN_DISK} | grep 'LINUX' | cut -d' ' -f1)

	# open the LUKS device if needed
	if ! silent cryptsetup status /dev/mapper/main; then
		echo -n "$_CRYPT_PASSPHRASE" | silent cryptsetup luksOpen -d /dev/stdin $linux main
	fi

	# mount raw LUKS device
	silent mount /dev/mapper/main /mnt

	##	Create all btrfs subvolumes	##
	for subvol in "${subvols[@]}"; do
		if ! silent btrfs subvolume create "/mnt/$subvol"; then
			log e "Failed to create btrfs subvolume : $subvol"
			false
		fi
	done

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}
