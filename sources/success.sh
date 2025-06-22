safe_reboot() {
	trap "$trap_msg" ERR

	prompt="[PROMPT] Are you sure you want to proceed?"

	echo "###############################################"
	echo "####                                       ####"
	echo "####          SUCCESS AND REBOOT           ####"
	echo "####                                       ####"
	echo "###############################################"
	printf "\n\n"
	log i "The execution of the script has finished successfully"
	log i "You are prompted for reboot"

	printf "\n"

	read -p "$prompt ('y/N'): " response
	if [[ ! "$response" =~ [yY] ]]; then
		log i "Not rebooting, goodbye!"
		cleanup
	fi

	umount -R /mnt
	reboot
}

