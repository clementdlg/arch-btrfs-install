## TODO
### urgent
- [ ] remove post-install and put all in install script
### features
- [ ] proper cleanup for post-install service
- [ ] implement the logic for the config file
    - [ ] Option to skip cryptsetup
    - [ ] CPU type (intel/amd ucode)
    - [ ] partition sizes
- [ ] have an easy way to mount all drives from the ISO

### safety
- [x] put disk erase prompt at the beginning
- [ ] create a backup of system files that are modified
- [ ] apply strict verification on config file values

### refactor
- [ ] refactor "disk.sh" to use global variables
- [ ] refactor the core script to use "utils.sh"
- [ ] Reimplement config file properly
