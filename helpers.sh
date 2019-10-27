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
