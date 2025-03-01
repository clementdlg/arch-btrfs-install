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

	args="noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol="
	mount -o "$args$1" \
		/dev/mapper/main \
		"/mnt$2"
}

mount_fs() {
	trap "$trap_msg" ERR

	esp=$(fdisk -x ${_MAIN_DISK} | grep 'ESP' | cut -d' ' -f1)

	# create BTRFS subvolumes
	mount /dev/mapper/main /mnt
	btrfs subvolume create /mnt/@
	btrfs subvolume create /mnt/@home
	btrfs subvolume create /mnt/@var
	umount /mnt

	mount_btrfs "@" "" # mount root
	mkdir -p /mnt/{boot,home,var} # create subvolumes dirs
	mount_btrfs "@home" "/home" # mount subvolumes
	mount_btrfs "@var" "/var"

	mount "$esp" /mnt/boot

	lsblk
}
