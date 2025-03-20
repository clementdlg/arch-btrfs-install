# GLOBAL SCOPE

# used for loging
green="\e[32m"
yellow="\e[33m"
red="\e[31m"
purple="\033[95m"
reset="\e[0m"

# This will be executed upon failure 
trap_msg='log e "$red[LINE $LINENO][FUNCTION ${FUNCNAME[0]}]$reset Failed to execute : <'\$BASH_COMMAND'>"; cleanup'

source_config() {
	trap "$trap_msg" ERR

	local config="arch-btrfs-install.conf"
	source "$config"

	log i "${FUNCNAME[0]} : success"
}

silent() {
	"$@" >/dev/null || return 1
}

create_workdir() {
	trap "$trap_msg" ERR
	check_state "${FUNCNAME[0]}" && return

	mkdir -p "$_WORKING_DIR" # create directory

	# create/overwrite log files
	echo "" > "$_LOGFILE"
	echo "" > "$_WORKING_DIR/$_STATE_FILE"

	update_state "${FUNCNAME[0]}" 
	log i "${FUNCNAME[0]} : success"
}

log() {
	msg="$2"
	[[ ! -z "$msg" ]]

	timestamp="[$(date +%H:%M:%S)]"

	label=""
	case "$1" in
		c) label="[CLEANUP]" ; color="$yellow" ;;
		e) label="[ERROR]" ; color="$red" ;;
		x) label="[EXIT]" ; color="$yellow" ;;
		d) label="[DEBUG]" ; color="$purple" ;;
		i) label="[INFO]" ; color="$green" ;;
	esac

	log="$timestamp$color$label$reset $msg "
	echo -e "$log"

	log="$timestamp$label $msg "

	if [[ -f ${_LOGFILE} ]]; then
		echo "$log" >> ${_LOGFILE}
	fi
}


check_state() {
	trap "$trap_msg" ERR

	fstate="$_WORKING_DIR/$_STATE_FILE"
	func_name="$1"

	[[ -f "$fstate" ]] || return 1

	grep "$func_name" "$fstate" || return 1

	log i "Recovered state for $func_name, skipping"
	return 0

}

update_state() {
	trap "$trap_msg" ERR

	fstate="$_WORKING_DIR/$_STATE_FILE"
	func_name="$1"

	[[ -f "$fstate" ]] || return 0

	echo "$func_name" >> "$fstate"
}

