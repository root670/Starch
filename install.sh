#!/bin/bash

source constants.sh
source helpers.sh

PASSWORD= # Set by user_setup()

#
# Main Functions
#
user_setup() {
    password1=$(whiptail --passwordbox "Enter password for user 'stepmania':" 8 50 3>&1 1>&2 2>&3)
    if ! [[ "$?" == "0" ]]; then installation_canceled; fi

    password2=$(whiptail --passwordbox "Confirm password:" 8 50 3>&1 1>&2 2>&3)
    if ! [[ "$?" == "0" ]]; then installation_canceled; fi

    if [[ "$password1" == "$password2" ]]; then
        PASSWORD=$(openssl passwd -6 "$password1")
        return 0
    else
        whiptail --msgbox "Passwords do not match, try again." 0 0
        user_setup # Prompt again.
    fi
}
disk_setup() {
    umount -R /mnt &>/dev/null
    local drive_list=$(lsblk -dnlpo NAME,MODEL -e 7,11)
    local options=()
    IFS=$'\n'
    for drive in ${drive_list}; do
        blk="${drive%% *}"
        name="${drive#* }"
        options+=("$blk" "$name")
    done
    IFS=' '
    device=$(whiptail --menu "Choose device to install the OS to" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
    if [ "$?" = "0" ]; then
        if (whiptail --yesno "Are you sure you want to use $device? All contents will be destroyed!" --defaultno 0 0) then
            clear
            echo -e "${GREEN}Creating partitions${NC}"
            begin_checked_section
            parted --script $device -- mklabel gpt \
                mkpart primary fat32 64d 512MiB  \
                set 1 esp on \
                mkpart primary ext4 512MiB -1MiB

            # Change device name if using NVMe
            if [ "${device::8}" == "/dev/nvm" ]; then device+="p"; fi

            # Wait for udev to create device nodes for the new partitions
            while [ ! -b ${device}"1" ]; do sleep 1; done
            while [ ! -b ${device}"2" ]; do sleep 1; done

            mkfs.vfat -F32 ${device}"1"
            mkfs.ext4 -F ${device}"2"

            mount ${device}2 /mnt
            mkdir /mnt/boot
            mount ${device}1 /mnt/boot

            # The UUID of the main partition is needed to setup the bootloader
            blkid ${device}2 | awk '{print $5}' > "/mnt${UUID_PATH}"
            end_checked_section
        else
            echo Installation canceled.
            exit 0
        fi
    else
        installation_canceled
    fi
}

package_setup() {
    echo -e "${GREEN}Installing packages${NC}"
    begin_checked_section

    pacstrap /mnt base linux base-devel glew libmad libjpeg libxinerama \
        libpulse libpng libvorbis libxrandr libva mesa cmake git yasm \
        xorg-xinit xorg-server vim dhcpcd alsa-utils ${CPU_VENDOR}-ucode lz4

    if has_nvidia_gpu; then
        echo -e "${GREEN}Installing NVIDIA driver${NC}"
        pacstrap /mnt nvidia
    fi

    end_checked_section
}

fstab_setup() {
    echo -e "${GREEN}Creating fstab${NC}"
    begin_checked_section
    genfstab -U /mnt >> /mnt/etc/fstab
    end_checked_section
}

after_pacstrap() {
    begin_checked_section
    mkdir -p /mnt/after-pacstrap
    cp after-pacstrap.sh constants.sh helpers.sh /mnt/after-pacstrap
    arch-chroot /mnt bash -c "cd /after-pacstrap && bash after-pacstrap.sh --password '$PASSWORD'"
    rm -rf /mnt/after-pacstrap
    end_checked_section

    if [[ -f /mnt/tmp/success ]]; then
        echo -e "${RED}Installation failed.${NC}"
    fi
}

finished() {
    whiptail 
    choice=$(whiptail --menu "Installation completed! What do you want to do now?" 0 0 0 "Reboot" "Reboot the machine" "Return in Shell" "Return to archiso with installation mounted to /mnt" 3>&1 1>&2 2>&3)
    if [[ $? -eq 0 ]]; then
        case "$choice" in
            "Reboot") umount -R /mnt &>/dev/null; reboot ;;
            *) clear; exit 0 ;;
        esac
    fi
}

check_root
check_internet_connection

user_setup
disk_setup
package_setup
fstab_setup
after_pacstrap

finished