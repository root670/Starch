#
# Utility functions used by the scripts.
#

check_root() {
    if ((EUID)); then
        echo -e "${RED}This script must be run as root.${NC}"
        exit 1
    fi
}

check_internet_connection() {
    if ! wget -q --spider https://google.com ; then
        echo -e "${RED}Not connected to the Internet.${NC}"
        exit 1
    fi
}

check_uefi() {
    if ! [ -d /sys/firmware/efi ] ; then
        echo -e "${RED}This script requires the system to boot in UEFI mode.${NC}"
        exit 1
    fi
}

check_nvidia() {
    if ! lspci|grep -qie 'VGA.*NVIDIA' ; then
        echo -e "${RED}This script requires an NVIDIA graphics card.${NC}"
        exit 1
    fi
}

arch_chroot() {
    arch-chroot /mnt /bin/bash -c "${1}"
}

# Wrap one or more commands around `begin_checked_section` and
# `end_checked_section` to exit the script early if any of the commands fail.
#
# Example:
# $ ls --badoption        <-- Will fail, but script will continue
# $ begin_checked_section
# $ ls
# $ ls --badoption        <-- Will fail, then script will exit
# $ end_checked_section
#

# echo an error message before exiting
trap '[ $? -gt 0 ] && echo "Previous command failed with exit code $?."' EXIT

# Exit script if any subsequent commands fail
begin_checked_section() {
    set -e
}

# Restore default behavior
end_checked_section() {
    set +e
}