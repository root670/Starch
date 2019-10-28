#!/bin/bash

#
# This script does the main installation tasks after pacstrap has been run by
# the main installer script.
#

source constants.sh
source helpers.sh

build_stepmania() {
    echo -e "${GREEN}Building StepMania${NC}"
    git clone --depth=1 https://github.com/stepmania/stepmania.git /stepmania
    mkdir /stepmania/build
    pushd /stepmania
    pushd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=/opt \
        -DCMAKE_BUILD_TYPE=Release \
        -DOpenGL_GL_PREFERENCE=GLVND \
        -DWITH_LTO=ON
    local processes=$(($(nproc) + 1))
    make -j${processes}
    popd
    cmake --install build --strip
    popd
    rm -rf /stepmania
}

configure_settings() {
    echo -e "${GREEN}Setting up configuration files${NC}"

    # Set initial configuration for StepMania
    mkdir -p ~/.stepmania-5.1/Save
    cat <<EOF >> /opt/.stepmania-5.1/Data/Static.ini
[Options]
Windowed=0
EOF

    # Run stepmania when `startx` is run
    cat <<EOF > ~/.xinitrc
#!/bin/sh

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "\$f" ] && . "\$f"
  done
  unset f
fi

exec /opt/stepmania-5.1/stepmania
EOF

    # Automatically login as root
    mkdir -p /etc/systemd/system/getty@tty1.service.d
    cat <<EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin root --noclear %I \$TERM
EOF

    # Start X after login on tty1
    cat <<EOF > ~/.bash_profile
if [[ -z \$DISPLAY ]] && [[ \$(tty) = /dev/tty1 ]]; then
    startx -- -nocursor
fi
EOF
}

timezone_setup() {
    echo -e "${GREEN}Setting timezone${NC}"
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    hwclock --systohc
}

locale_setup() {
    echo -e "${GREEN}Setting locale${NC}"
    echo "${LANG} UTF-8" >> /etc/locale.gen
    echo "LANG=${LANG}" >> /etc/locale.conf
    locale-gen
}

bootloader_setup() {
    echo -e "${GREEN}Setting up bootloader${NC}"
    bootctl install
    local uuid=$(cat $UUID_PATH)
    cat <<EOF > /boot/loader/loader.conf
timeout 0
default arch
EOF
    cat <<EOF > /boot/loader/entries/arch.conf
title ArchLinux
linux /vmlinuz-linux
initrd ${CPU_VENDOR}-ucode.img
initrd /initramfs-linux.img
options root=${uuid} rw
EOF
}

initramfs_setup() {
    # Compress with lz4
    echo COMPRESSION=\"lz4\" >> /etc/mkinitcpio.conf
    echo COMPRESSION_OPTIONS=\"-9\" >> /etc/mkinitcpio.conf
    sed -i -e "s/MODULES=(\(.*\))/MODULES=(\1 lz4 lz4_compress)/" /etc/mkinitcpi.conf
}

cleanup() {
    rm -rf /var/cache/pacman/pkg
    touch /tmp/success
}

build_stepmania
configure_settings
timezone_setup
locale_setup
bootloader_setup
cleanup