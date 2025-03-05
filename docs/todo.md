## TODO
### fix
- [x] Error handling if disk is already mounted
- [ ] Remove check config banner

- [ ] no error handling when running commands in chroot
    - [ ] command adduser crashes the script if user already exists

- [ ] finish implementing the docs
    - [ ] post-install

### safety
- [x] Logging
    - [x] Log file
    - [x] Stdin logs

- [ ] add ability to restart the script where it ended last run
- [ ] improve failsafe

- [ ] pacstrap :
    - [ ] verify what happens if "pacstrap base" fails
    - [ ] maybe remove all files except the mountpoints if "tail -1 STATE == pacstrap"

### config
- [ ] implement the logic for the config file
    - [ ] Option to skip cryptsetup
    - [ ] CPU type (intel/amd ucode)
    - [ ] partition sizes

- [ ] Create config documentation
