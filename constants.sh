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

# Change these variables as needed
readonly KEYMAP='us'
readonly LANG='en_US.UTF-8'
readonly TIMEZONE='US/Pacific'
