#
# Constant values used by the scripts.
#

readonly PACMAN_OPTIONS='--noconfirm --color always'
readonly GREEN='\e[32m\e[1m'
readonly RED='\e[31m\e[1m'
readonly NC='\e[0m'
if cat /proc/cpuinfo|grep -qie 'vendor.*Intel' ; then
    readonly CPU_VENDOR='intel'
elif cat /proc/cpuinfo|grep -qie 'vendor.*AMD' ; then
    readonly CPU_VENDOR='amd'
else
    echo -e "${RED}Couldn't detect CPU vendor.${NC}"
    exit 1
fi
readonly UUID_PATH='/uuid.tmp'
readonly USERNAME='stepmania'

# Change these variables as needed
readonly KEYMAP='us'
readonly LANG='en_US.UTF-8'
readonly TIMEZONE='US/Pacific'

# Packages that will always be installed on the system
readonly PACKAGES_STANDARD='base linux base-devel glew libmad libjpeg libxinerama libpulse libpng libvorbis libxrandr libva mesa cmake git yasm xorg-xinit xorg-server vim dhcpcd alsa-utils lz4'
# Packages that may be installed depending on the hardware in use, but need to
# be included in the ISO image
readonly PACKAGES_ISO='amd-ucode intel-ucode nvidia'