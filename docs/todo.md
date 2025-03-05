## TODO
### fix
- [ ] Fix :
    - [ ] Error handling if disk is already mounted
    - [ ] Remove check config banner

- [ ] finish implementing the docs
    - [ ] post-install

- [ ] no error handling when running commands in chroot

### safety
- [ ] Logging
    - [ ] Log file
    - [ ] Stdin logs

- [ ] improve failsafe
    - [ ] force repartitionning if pacstrap fails
- [ ] add ability to restart the script where it ended last run

### config
- [ ] implement the logic for the config file
    - [ ] Option to skip cryptsetup
    - [ ] CPU type (intel/amd ucode)
    - [ ] partition sizes

- [ ] Create config documentation
