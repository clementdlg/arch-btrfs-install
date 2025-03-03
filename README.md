# arch-btrfs-install

## TODO
- [ ] Fix :
    - [ ] Error handling if disk is already mounted
- [ ] finish implementing the docs
    - [x] GRUB setup
    - [x] User setup
    - [ ] post-install
- [ ] Logging
    - [ ] Log file
    - [ ] Stdin logs
- [ ] implement the logic for the config file
    - [ ] Option to skip cryptsetup
    - [ ] CPU type (intel/amd ucode)
- [ ] improve failsafe
- [ ] add "--recover" : ability to restart the script where it ended last run
    - [ ] write a test.sh file
