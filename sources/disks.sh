#!/usr/bin/env bash

disk_part_util() {
	trap "$trap_msg" ERR
	sgdisk -n$1::"$2" \
			-t$1:"$3" \
			-c$1:"$4" \
			${_MAIN_DISK}
}

partitionning_disk() {
	trap "$trap_msg" ERR

	[[ -b "$_MAIN_DISK" ]]

	# Wipe disk
	sgdisk -o ${_MAIN_DISK}

	# partitions ; num; size; type; name
	disk_part_util   1   +2G "EF00" "ESP"
	disk_part_util   2   +4G "8200" "SWAP"
	disk_part_util   3    "" "8300" "LINUX"

	sgdisk -p $_MAIN_DISK

	gdisk -l ${_MAIN_DISK}
}

formatting_disk() {
	trap "$trap_msg" ERR

	esp=$(fdisk -x ${_MAIN_DISK} | grep 'ESP' | cut -d' ' -f1)
	swap=$(fdisk -x ${_MAIN_DISK} | grep 'SWAP' | cut -d' ' -f1)
	linux=$(fdisk -x ${_MAIN_DISK} | grep 'LINUX' | cut -d' ' -f1)

	mkfs.fat -F 32 $esp # create boot partition

	mkswap $swap # create swap partition
	# swapon $swap # enable swap partition

	echo -n "$_CRYPT_PASSPHRASE" | cryptsetup luksFormat -d /dev/stdin $linux

	echo -n "$_CRYPT_PASSPHRASE" | cryptsetup luksOpen -d /dev/stdin $linux main

	mkfs.btrfs /dev/mapper/main

	lsblk
}

mount_btrfs() {
	trap "$trap_msg" ERR

	subvol="$1"
	mountpoint="$2"
	args="noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol="

	mount --mkdir -o "$args$subvol" \
		/dev/mapper/main \
		"/mnt$mountpoint"
}

mount_fs() {
	trap "$trap_msg" ERR

	esp=$(fdisk -x ${_MAIN_DISK} | grep 'ESP' | cut -d' ' -f1)

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

	[[ "${#subvols[@]}" == "${#mountpoints[@]}" ]]

	# mount the filesystem
	mount /dev/mapper/main /mnt

	# create each subvolume
	for subvol in "${subvols[@]}"; do
		btrfs subvolume create "/mnt/$subvol"
	done

	umount /mnt # unmount before remounting with appropriate options

	# mount each subvolume
	for i in "${!mountpoints[@]}"; do
		mount_btrfs "${subvols[$i]}" "${mountpoints[$i]}"
	done

	mount --mkdir "$esp" /mnt/boot

	lsblk
}
