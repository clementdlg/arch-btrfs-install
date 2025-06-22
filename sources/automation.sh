configure_timeshift() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	prefix="/mnt"
	config="timeshift.json"
	config_path="$prefix/etc/timeshift/$config"
	dev_uuid="$(blkid | grep "/dev/mapper/main" | cut '-d"' -f2)"
	parent_uuid="$(blkid -t PARTLABEL="LINUX" | cut '-d"' -f2)"

	# copy timeshift config
	install -Dm644 "$_SCRIPT_DIR/files/$config" "$config_path"

	# set default backup device
	sed -i "s/MY_BACKUP_UUID_HERE/$dev_uuid/" "$config_path"
	sed -i "s/MY_PARENT_UUID_HERE/$parent_uuid/" "$config_path"

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

grub_btrfsd() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	file="/mnt/usr/lib/systemd/system/grub-btrfsd.service"

	[[ -f "$file" ]]

	sed -i '/^ExecStart=/s| /.snapshots| --timeshift-auto|' "$file"
	
	arch "systemctl enable grub-btrfsd"

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

install_autosnap() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	# TODO:: just copy the files over. Only the script needs to be pulled from internet
	pkg_name="timeshift-autosnap"
	url="https://gitlab.com/gobonja/$pkg_name.git"
	repo_path="$_WORKING_DIR/$pkg_name"
	prefix="/mnt"
	hook="00-$pkg_name.hook"

	silent pacman -S git --noconfirm

	mkdir -p "$repo_path"
	git clone "$url" "$repo_path"

    install -Dm644 "$repo_path/$hook" "$prefix/usr/share/libalpm/hooks/$hook"
    install -Dm644 "$repo_path/$pkg_name.conf" "$prefix/etc/$pkg_name.conf"
    install -Dm755 "$repo_path/$pkg_name" "$prefix/usr/bin/$pkg_name"

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

configure_autosnap() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	prefix="/mnt"
	config="$prefix/etc/timeshift-autosnap.conf"
	hook="$prefix/usr/share/libalpm/hooks/00-timeshift-autosnap.hook"

	# TODO: remove the 4 sed and just copy the file at the right place in the previous function
	# set max snapshots to 15
	sed -i 's/maxSnapshots=.*/maxSnapshots=15/' "$config"

	# set update grub to false to avoid conflicts
	sed -i 's/updateGrub=.*/updateGrub=false/' "$config"

	# add snapshots triggers
	sed -i '/^Operation = Upgrade$/a Operation = Install\nOperation = Remove' "$hook"

	# change description
	sed -i '/^Description =/s/upgrade/transaction/' "$hook"
	
	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}
