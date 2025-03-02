arch() {
	arch-chroot /mnt "$@"
}

bootstrap() {
	pacstrap -K /mnt base base-devel linux linux-firmware intel-ucode vim
}

set_locale() {
	trap "$trap_msg" ERR
	arch-chroot /mnt ln -sf /usr/share/zoneinfo/${_TIMEZONE} /etc/localtime
	arch-chroot /mnt hwclock --systohc
	arch-chroot /mnt echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
	arch-chroot /mnt locale-gen
	arch-chroot /mnt echo "LANG=en_US.UTF-8" > /etc/locale.conf
}

host_settings() {
	trap "$trap_msg" ERR

	echo "${_HOSTNAME}" > /etc/hostname

	arch echo "127.0.0.1   localhost" > /etc/hostname
	arch echo "::1         localhost" > /etc/hostname
	arch echo "127.0.0.1   ${_HOSTNAME}.localdomain ${_HOSTNAME}" > /etc/hostname

	arch echo "KEYMAP=${_KEYMAP}" > /etc/vconsole.conf
	arch echo "FONT='ter-228b'" > /etc/vconsole.conf
	
	arch echo "root:${_ROOT_PASSWORD}" | chpasswd
}

install_system_utils() {
	arch pacman -S grub-btrfs \
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
		--noconfirm
}

systemd_services() {
	arch systemctl enable NetworkManager
	arch systemctl enable firewalld
	arch systemctl enable fstrim.timer
	arch systemctl enable reflector.timer
}

