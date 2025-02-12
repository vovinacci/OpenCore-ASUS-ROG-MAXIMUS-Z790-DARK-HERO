# OpenCore configuration

You may find a great installation guide [here](https://dortania.github.io/OpenCore-Install-Guide/installer-guide/).

- [Dortania OpenCore Install Guide](https://dortania.github.io/OpenCore-Install-Guide/)
- [OpenCanopy](https://dortania.github.io/OpenCore-Post-Install/cosmetic/gui.html)
- [FileVault](https://dortania.github.io/OpenCore-Post-Install/universal/security/filevault.html)

## ACPI

As per [Dortania Getting started with ACPI](https://dortania.github.io/Getting-Started-With-ACPI/), created SSDTs:

- [SSDT-EC.aml](../efi/OC/ACPI/SSDT-EC.aml)
- [SSDT-PLUG-ALT.aml](../efi/OC/ACPI/SSDT-PLUG-ALT.aml)
- [SSDT-RTCAWAC.aml](../efi/OC/ACPI/SSDT-RTCAWAC.aml)
- [SSDT-SBUS-MCHC.aml](../efi/OC/ACPI/SSDT-SBUS-MCHC.aml)
- [SSDT-USBX.aml](../efi/OC/ACPI/SSDT-USBX.aml)

## CPU

Intel Raptor Lake is not officially supported by macOS.

[CPUFriend](https://github.com/acidanthera/CPUFriend/blob/master/Instructions.md), accompanied by
[CPUFriendDataProvider.kext](../efi/OC/Kexts/CPUFriendDataProvider.kext) is used.

## USB Mapping

Based on Dortania [USB Mapping Guide](https://dortania.github.io/OpenCore-Post-Install/usb/) and [Intel USB mapping](https://github.com/corpnewt/USBMap).

TODO: Add USB port mapping picture.

Resulting [USBMap.kext](../efi/OC/Kexts/USBMap.kext) is used.

## Drivers

- OpenCore
  - `AudioDxe.efi` - HDA audio support driver in UEFI firmware for most Intel and some other analog audio controllers.
  - `CrScreenshotDxe.efi` - Screenshot making driver saving images to the root of OpenCore partition or any available writeable filesystem upon pressing F10.
  - `OpenCanopy.efi` - OpenCore plugin implementing graphical interface.
  - `OpenLinuxBoot.efi` - OpenCore plugin allowing direct detection and booting of Linux distributions from OpenCore, without chainloading via GRUB.
  - `OpenRuntime.efi` - OpenCore plugin implementing OC_FIRMWARE_RUNTIME protocol.
  - `ResetNvramEntry.efi` - OpenCore plugin adding a configurable Reset NVRAM entry to the boot picker menu.
  - `ToggleSipEntry.efi` - OpenCore plugin adding a configurable Toggle SIP entry to the boot picker menu.
- [OcBinaryData](https://github.com/acidanthera/OcBinaryData)
  - [HfsPlus.efi](https://github.com/acidanthera/OcBinaryData/blob/master/Drivers/HfsPlus.efi) - Proprietary HFS file system driver with bless support commonly
    found in Apple firmware.
  - [ext4_x64](https://github.com/acidanthera/OcBinaryData/blob/master/Drivers/ext4_x64.efi) - Open source EXT4 file system driver, required for booting with
    OpenLinuxBoot from the file system most commonly used with Linux.

## Kexts

- [AppleALC](https://github.com/acidanthera/AppleALC) - Native macOS HD audio for not officially supported codecs.
- [CPUFriend](https://github.com/acidanthera/CPUFriend) - Dynamic macOS CPU power management data injection.
- [Lilu](https://github.com/acidanthera/Lilu) - Arbitrary kext and process patching on macOS.
- [NVMeFix](https://github.com/acidanthera/NVMeFix) - Set of patches for the Apple NVMe storage driver `IONVMeFamily` to improve compatibility with non-Apple
  SSDs.
- [RestrictEvents](https://github.com/acidanthera/RestrictEvents) - Lilu Kernel extension for blocking unwanted processes causing compatibility issues.
- [SMCRadeonSensors](https://github.com/ChefKissInc/SMCRadeonSensors) - AMD GPU temperature monitoring on macOS.
- [VirtualSMC](https://github.com/acidanthera/VirtualSMC) (`SMCProcessor.kext`, `SMCSuperIO.kext` and `VirtualSMC.kext`)
- [WhateverGreen](https://github.com/acidanthera/WhateverGreen) - Various patches necessary for certain ATI/AMD/Intel/Nvidia GPUs.

### Resources

- [OpenCanopy](https://dortania.github.io/OpenCore-Post-Install/cosmetic/gui.html) theme - `Acidanthera\GoldenGate`
- [OcBinaryData](https://github.com/acidanthera/OcBinaryData) - [Resources/](https://github.com/acidanthera/OcBinaryData/blob/master/Resources)

### Tools

- OpenCore
  - `CleanNvram.efi` - Reset NVRAM alternative, bundled as a standalone tool.
  - `OpenControl.efi` - Unlock and lock back NVRAM protection for other tools to be able to get full NVRAM access when launching from OpenCore.
  - `OpenShell.efi` - OpenCore-configured UEFI Shell for compatibility with a broad range of firmware.
  - `ResetSystem.efi` - Utility to perform system reset.
- [PassMark MemTest86](https://www.memtest86.com/)
