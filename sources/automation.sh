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
