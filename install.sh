#!/bin/bash

PACMAN_OPTIONS='--noconfirm --color always'
GREEN='\e[32m\e[1m'
RED='\e[31m\e[1m'
NC='\e[0m'
if cat /proc/cpuinfo|grep -qie 'vendor.*Intel' ; then
    CPU_VENDOR='intel'
elif cat /proc/cpuinfo|grep -qie 'vendor.*AMD' ; then
    CPU_VENDOR='amd'
else
    echo -e "${RED}Couldn't detect CPU vendor.${NC}"
    exit 1
fi

# Change these variables as needed
KEYMAP='us'
LANG='en_US.UTF-8'
TIMEZONE='US/Pacific'

#
# Helper Functions
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


#
# Main Functions
#
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
            parted --script $device -- mklabel gpt \
                mkpart primary fat32 64d 512MiB  \
                set 1 esp on \
                mkpart primary ext4 512MiB -1MiB

            # Change device name if using NVMe
            if [ "${device::8}" == "/dev/nvm" ]; then device=${device}"p"; fi

            # Wait for udev to create device nodes for the new partitions
            while [ ! -b ${device}"1" ]; do sleep 1; done
            while [ ! -b ${device}"2" ]; do sleep 1; done

            mkfs.vfat -F32 ${device}"1"
            mkfs.ext4 -F ${device}"2"

            mount ${device}2 /mnt
            mkdir /mnt/boot
            mount ${device}1 /mnt/boot
        else
            echo -e "Installation canceled.${NC}"
            exit 0
        fi
    else
        echo -e "Installation canceled.${NC}"
        exit 0
    fi
}

package_setup() {
    echo -e "${GREEN}Refreshing package list${NC}"
    pacman $PACMAN_OPTIONS -Syy

    echo -e "${GREEN}Installing packages${NC}"
    pacstrap /mnt base linux base-devel glew libmad libjpeg libxinerama \
        libpulse libpng libvorbis libxrandr libva mesa cmake git yasm \
        xorg-xinit xorg-server vim dhcpcd alsa-utils nvidia ${CPU_VENDOR}-ucode
}

bootloader_setup() {
    echo -e "${GREEN}Setting up bootloader${NC}"
    arch_chroot "bootctl install"
    local uuid=$(blkid ${device}2|awk '{print $5}')
    arch_chroot "cat <<EOF > /boot/loader/loader.conf
timeout 0
default arch
EOF"
    arch_chroot "cat <<EOF > /boot/loader/entries/arch.conf
title ArchLinux
linux /vmlinuz-linux
initrd /${CPU_VENDOR}-ucode.img
initrd /initramfs-linux.img
options root=${uuid} rw
EOF"
}

fstab_setup() {
    echo -e "${GREEN}Creating fstab${NC}"
    genfstab -U /mnt >> /mnt/etc/fstab
}

timezone_setup() {
    echo -e "${GREEN}Setting timezone${NC}"
    arch_chroot "ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime"
    arch_chroot "hwclock --systohc"
}

locale_setup() {
    echo -e "${GREEN}Setting locale${NC}"
    arch_chroot "echo \"${LANG} UTF-8\" >> /etc/locale.gen"
    arch_chroot "echo \"LANG=${LANG}\" >> /etc/locale.conf"
    arch_chroot "locale-gen"
}

build_stepmania() {
    echo -e "${GREEN}Building StepMania${NC}"
    arch_chroot "git clone --depth=1 https://github.com/stepmania/stepmania.git /stepmania"
    arch_chroot "mkdir /stepmania/build"
    arch_chroot "cd /stepmania/build && cmake .. \
        -DCMAKE_INSTALL_PREFIX=/opt \
        -DCMAKE_BUILD_TYPE=Release \
        -DOpenGL_GL_PREFERENCE=GLVND \
        -DWITH_LTO=ON"
    processes=$(($(nproc) + 1))
    arch_chroot "cd /stepmania/build && make -j${processes}"
    arch_chroot "cd /stepmania && cmake --install build --strip"
    arch_chroot "rm -rf /stepmania"
}

configure_startup() {
    echo -e "${GREEN}Doing final configuration${NC}"

    # Set initial configuration for StepMania
    arch_chroot "mkdir -p ~/.stepmania-5.1/Save"
    arch_chroot "cat <<EOF >> ~/.stepmania-5.1/Save/Static.ini
[Options]
Windowed=0
EOF"

    # Run stepmania when `startx` is run
    arch_chroot 'cat <<EOF > ~/.xinitrc
#!/bin/sh

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "\$f" ] && . "\$f"
  done
  unset f
fi

exec /opt/stepmania-5.1/stepmania
EOF'

    # Automatically login as root
    arch_chroot 'mkdir -p /etc/systemd/system/getty@tty1.service.d/ && \
cat <<EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin root --noclear %I \$TERM
EOF'

    # Start X after login on tty1
    arch_chroot 'cat <<EOF > ~/.bash_profile
if [[ -z \$DISPLAY ]] && [[ \$(tty) = /dev/tty1 ]]; then
    startx -- -nocursor
fi
EOF'
}

cleanup() {
    arch_chroot "rm -rf /var/cache/pacman/pkg/"
    umount -R /mnt &>/dev/null
}

check_root
check_nvidia
check_internet_connection

disk_setup
package_setup
build_stepmania
configure_startup
fstab_setup
timezone_setup
locale_setup
bootloader_setup
cleanup
