# Starch

A minimal Arch Linux distribution for running StepMania on dedicated rhythm game
machines.

## Features

* Unattended installation. You only need to specify a device to install to
* Boots to StepMania running in its own X session without a desktop environment
* Downloads and compiles latest StepMania revision from GitHub
* Uses latest NVIDIA driver

## System Requirements

* NVIDIA GeForce 600 or newer graphics card
* System capable of booting in UEFI mode
* Internet connection at time of installation

## Installation Instructions

1. Download latest Arch installation media from
   [here](https://www.archlinux.org/download/) and write it to a USB drive using
   Rufus or dd.

2. Boot from installation media using the UEFI boot partition. You may need to
   disable secure boot if it's currently enabled.

3. Ensure you have a working Internet connection once the terminal prompt
   appears. For wired connections, a connection should be established
   automatically using DHCP. For wireless connections, `wifi-menu` can be used
   to connect to a network. The
   [ArchWiki](https://wiki.archlinux.org/index.php/Network_configuration)
   provides more detailed instructions if needed.

4. Download, extract, and run the install script to begin installation:

```
wget github.com/root670/Starch/archive/master.zip
bsdtar -xf master.zip
cd Starch
sh install.sh
```

## Notes

* Currently everything is run as root on the installed system. A locked down
  user will be used in the future.
* Terminal can be accessed by holding `Alt` and pressing `F2` through `F7`.
* IO boards for pads and/or lights (PIUIO, P4IO, LitBoard, MiniMaid, etc.)
  aren't supported out-of-the-box. If you're able to get any IO boards working
  with Starch, please let me know and I'll look into adding support for it in
  the installation script.
* If using in an SD cabinet with a CRT monitor, you'll need to create a custom X
  config script similar to how ITG does.

## Disclaimer

**Use at your own risk!** This has been tested in VirtualBox and on my own
desktop, but **not in an actual cabinet**.