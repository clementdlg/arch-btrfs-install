#!/usr/bin/env bash

set -euo pipefail

# debug
date="$(date)"
echo "post install $date" > /root/post-inst.log

# set working directory
path="/root/post-install"
cd "$path"

# public functions
source_files() {
	source "$path/commons.sh" || false

	echo "${FUNCNAME[0]} : success"
}

grub_btrfsd() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	file="/usr/lib/systemd/system/grub-btrfsd.service"
	sed -i '/^ExecStart=/s| /.snapshots| --timeshift-auto|' "$file"
	
	systemctl enable --now grub-btrfsd

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

take_snapshot() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	comment="FIRST BOOT"
	timeshift --create --comments "$comment" --tags D

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

autosnap() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	pkg_name="timeshift-autosnap"
	url="https://gitlab.com/gobonja/$pkg_name.git"
	destination="$_WORKING_DIR/$pkg_name"

	mkdir -p $destination
	git clone $url $destination

    install -Dm644 "$destination/00-timeshift-autosnap.hook" /usr/share/libalpm/hooks/00-timeshift-autosnap.hook
    install -Dm644 "$destination/timeshift-autosnap.conf" /etc/timeshift-autosnap.conf
    install -Dm755 "$destination/timeshift-autosnap" /usr/bin/timeshift-autosnap

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

postinstall() {
	# imported
	source_files
	source_config
	create_workdir

	# grub_btrfsd
	# take_snapshot
	autosnap
}

postinstall
