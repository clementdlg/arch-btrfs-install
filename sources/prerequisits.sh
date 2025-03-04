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

	silent cat /sys/firmware/efi/fw_platform_size

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

	timedatectl set-timezone "$_TIMEZONE"
	timedatectl set-ntp true

	log i "${FUNCNAME[0]} : success"
}


update_repos() {
	trap "$trap_msg" ERR

	mirror_list="/etc/pacman.d/mirrorlist"
	silent reflector -c "$_COUNTRY" -a 12 --sort rate --save "$mirror_list" 2>/dev/null

	silent pacman -Syy archlinux-keyring --noconfirm 2>/dev/null

	log i "${FUNCNAME[0]} : success"
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
	log i "Proceeding to installation"
}
