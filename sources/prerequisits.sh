#!/usr/bin/env bash


verify_config_keys() {
	trap "$trap_msg" ERR

	export valid_keys=(
		"_USER"
		"_USER_PASSWORD"
		"_ROOT_PASSWORD"
		"_HOSTNAME"
		"_MAIN_DISK"
		"_TIMEZONE"
		"_COUNTRY"
		"_KEYMAP"
		"_WORKING_DIR"
		"_LOGFILE"
		"_CRYPT_PASSPHRASE"
	)

	echo "##########################################"
	echo "####        ARCH BTRFS INSTALL        ####"
	echo "####         VERIFYING CONFIG         ####"
	echo "##########################################"

	for key in "${valid_keys[@]}"; do
		if env | silent grep --color=always "$key"; then
			log i "Found key : $key"
		else
			log e "Missing key : $key"
			false
		fi
	done

	log i "${FUNCNAME[0]} : success"
}


check_boot_mode(){
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	silent cat /sys/firmware/efi/fw_platform_size

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}


check_connection(){
	trap "$trap_msg" ERR

	ip="1.1.1.1"
	silent ping -c3 $ip
	log i "${FUNCNAME[0]} : success"
}


set_time() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	timedatectl set-timezone "$_TIMEZONE"
	timedatectl set-ntp true

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}


update_repos() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	mirror_list="/etc/pacman.d/mirrorlist"
	silent reflector -c "$_COUNTRY" -a 12 --sort rate --save "$mirror_list" 2>/dev/null

	silent pacman -Syy archlinux-keyring --noconfirm 2>/dev/null

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}



