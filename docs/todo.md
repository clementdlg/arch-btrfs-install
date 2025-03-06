## TODO
### fix
- [x] Error handling if disk is already mounted
- [x] Remove check config banner

- [x] no error handling when running commands in chroot
    - [x] command adduser crashes the script if user already exists
    - [x] script crashed if silenced command fails

### safety
- [x] Logging
    - [x] Log file
    - [x] Stdin logs

- [ ] add ability to restart the script where it ended last run
- [ ] improve failsafe

- [ ] pacstrap :
    - [x] verify what happens if "pacstrap base" fails
    - [x] maybe remove all files except the mountpoints if "tail -1 STATE == pacstrap"

### features
- [ ] implement the logic for the config file
    - [ ] Option to skip cryptsetup
    - [ ] CPU type (intel/amd ucode)
    - [ ] partition sizes

- [ ] finish implementing the docs
    - [ ] post-install

- [ ] Reimplement config file properly

- [ ] rewrite "remount.sh"
