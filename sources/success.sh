enable_post_install() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	# Copy post-install service
	service="post-install.service"
	unitfile="config/$service"
	systemd="/mnt/etc/systemd/system"

	if [[ ! -f "$unitfile" ]]; then
		log e "file $unitfile does not exist"
		false
	fi

	cp "$unitfile" "$systemd"

	# Copy post install script
	script="sources/postinstall.sh"
	root="/mnt/root"

	if [[ ! -f "$script" ]]; then
		log e "file $script does not exist"
		false
	fi

	cp "$script" "$root"
	chmod +x "$root/postinstall.sh"

	# enable service
	arch "systemctl enable $service"

	# reset first-boot
	rm /mnt/etc/machine-id

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

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

