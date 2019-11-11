#!/bin/bash

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

source "$DIR/constants.sh"
source "$DIR/helpers.sh"

OUTPUT_DIRECTORY=/share/iso

create_iso() {
    begin_checked_section

    # Install archiso
    echo -e "${GREEN}Installing archiso${NC}"
    pacman -Syy --noconfirm archiso

    # Copy archiso "releng" profile
    mkdir iso_build_dir
    cp -r /usr/share/archiso/configs/releng/* iso_build_dir/

    # Download packages to create an offline repository to be used by install.sh
    echo -e "${GREEN}Downloading packages${NC}"
    mkdir -p iso_build_dir/work/iso/repo
    pushd iso_build_dir/work/iso/repo
    pacman -Syw --dbpath /tmp --cachedir . --noconfirm $PACKAGES_STANDARD $PACKAGES_ISO
    repo-add ./custom.db.tar.gz *.tar*
    popd

    # Use the offline repository in the ISO environment
    echo -e "${GREEN}Tweaking ISO environment${NC}"
    cat <<EOF >> iso_build_dir/airootfs/root/customize_airootfs.sh
cat <<EOF2 > temp
[custom]
SigLevel = Never
Server = file:///run/archiso/bootmnt/repo
EOF2
cat temp /etc/pacman.conf > /etc/pacman.conf.temp
rm temp
mv /etc/pacman.conf.temp /etc/pacman.conf
sed -i -e "s@\(#CacheDir.*$\)@CacheDir = /run/archiso/bootmnt/repo@" /etc/pacman.conf
EOF

    # Copy Starch install scripts to ISO environment's home directory
    mkdir -p iso_build_dir/airootfs/root/Starch
    cp "$DIR/after-pacstrap.sh" "$DIR/constants.sh" "$DIR/helpers.sh" "$DIR/install.sh" "$DIR/README.md" iso_build_dir/airootfs/root/Starch/

    # Build ISO
    echo -e "${GREEN}Building ISO${NC}"
    pushd iso_build_dir
    ./build.sh -v -o "$OUTPUT_DIRECTORY"
    popd

    end_checked_section
}

check_root
create_iso