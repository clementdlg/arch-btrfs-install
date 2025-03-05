bootstrap() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	pacstrap -K /mnt \
		base \
		base-devel \
		linux \
		linux-firmware \
		intel-ucode \
		vim

	genfstab -U /mnt >> /mnt/etc/fstab

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

set_locale() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	arch "ln -sf /usr/share/zoneinfo/${_TIMEZONE} /etc/localtime"
	arch "hwclock --systohc"
	arch "echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen"
	arch "locale-gen"
	arch "echo 'LANG=en_US.UTF-8' > /etc/locale.conf"

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

host_settings() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	hosts="/etc/hosts"
	console="/etc/vconsole.conf"

	arch "echo \"${_HOSTNAME}\" > /etc/hostname"

	arch "echo '127.0.0.1   localhost' >> $hosts"
	arch "echo '::1         localhost' >> $hosts"
	arch "echo \"127.0.0.1   ${_HOSTNAME}.localdomain ${_HOSTNAME}\" >> $hosts"

	arch "echo \"KEYMAP=${_KEYMAP}\" >> $console"
	arch "echo FONT='ter-228b' >> $console"

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

install_system_utils() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	arch "pacman -S grub-btrfs \
		grub \
		efibootmgr \
		networkmanager \
		timeshift \
		reflector \
		tmux \
		man-db \
		man-pages \
		bash-completion \
		inotify-tools \
		git \
		rsync \
		terminus-font \
		btrfs-progs \
		firewalld \
		--noconfirm"

	arch "systemctl enable NetworkManager"
	arch "systemctl enable firewalld"
	arch "systemctl enable fstrim.timer"
	arch "systemctl enable reflector.timer"

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

add_user() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	# creating user
	arch "useradd -mG wheel ${_USER}"
	arch "echo \"${_USER}:${_USER_PASSWORD}\" | chpasswd"
	arch "echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers"
	
	# setting root password
	arch "echo \"root:${_ROOT_PASSWORD}\" | chpasswd"

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}
