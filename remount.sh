#!/usr/bin/env bash
set -xeuo pipefail

mount_btrfs() {
	trap "$trap_msg" ERR

	subvol="$1"
	mountpoint="$2"
	args="noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol="

	mount --mkdir -o "$args$subvol" \
		/dev/mapper/main \
		"/mnt$mountpoint"
}

remount_fs() {
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

	# mount each subvolume
	for i in "${!mountpoints[@]}"; do
		mount_btrfs "${subvols[$i]}" "${mountpoints[$i]}"
	done

	mount "$esp" /mnt/boot

	lsblk
}

remount_fs
