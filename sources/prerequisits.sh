#!/usr/bin/env bash


verify_config_keys() {
	trap 'echo "[EXIT] failed at '${FUNCNAME[0]}' : $key not found"' ERR

	export valid_keys=(
		"_USER"
		"_USER_PASSWORD"
		"_ROOT_PASSWORD"
		"_HOSTNAME"
		"_MAIN_DISK"
		"_FILESYSTEM"
		"_SWAP_SIZE"
		"_TIMEZONE"
		"_COUNTRY"
		"_KEYMAP"
		"_WORKING_DIR"
		"_LOGFILE"
		"_CRYPT_PASSPHRASE"
	)

	for key in "${valid_keys[@]}"; do
		var=$(env | grep "$key")
	done
}


check_boot_mode(){
	trap 'echo "[EXIT] failed to '${FUNCNAME[0]}' : BIOS is not supported, use UEFI"' ERR

	silent cat /sys/firmware/efi/fw_platform_size
}


check_connection(){
	trap 'echo "[EXIT] failed to '${FUNCNAME[0]}' : no internet"' ERR

	ip="1.1.1.1"
	silent ping -c3 $ip
}


set_time() {
	trap 'echo "[EXIT] failed to '${FUNCNAME[0]}'"' ERR
	timedatectl set-timezone "$_TIMEZONE"
	timedatectl set-ntp true
}


update_repos() {
	trap 'echo "[EXIT] failed to '${FUNCNAME[0]}'"' ERR

	mirror_list="/etc/pacman.d/mirrorlist"
	silent reflector -c "$_COUNTRY" -a 12 --sort rate --save "$mirror_list"

	silent pacman -Syy archlinux-keyring --noconfirm
}


display_warning() {
	trap 'printf "[EXIT] Operation canceled\n[EXIT] Check the configuration file\n"' ERR

	prompt="[PROMPT] Are you sure you want to proceed?"

	echo "##########################################"
	echo "####        ARCH BTRFS INSTALL        ####"
	echo "####             WARNING              ####"
	echo "##########################################"

	printf "\n\n1) Verfiy the parameters\n"
	env | grep -E '^_[A-Z_]{1,}='

	printf "\n"
	read -p "$prompt (y/N): " response
	[[ "$response" =~ ^[Yy]$ ]]

	printf "\n\n2) YOU ARE ABOUT TO WIPE OUT $_MAIN_DISK\n\n"
	fdisk -l /dev/vda

	printf "\n"
	read -p "$prompt (type 'YES'): " response
	[[ "$response" == "YES" ]]
	printf "\nProceeding to install...\n"
}
