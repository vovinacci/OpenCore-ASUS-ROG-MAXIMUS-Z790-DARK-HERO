# OpenCore for Asus ROG MAXIMUS Z790 DARK HERO + i9-14900K + Asus RX 6900 XT

> [!WARNING]
> **This repository is archived and no longer maintained.**
>
> Apple ends Intel (x86_64) support in 2027, and macOS Sequoia `15.2` (`24C101`) is the last version running on this build.
> The configuration is left as-is for reference; no further OpenCore or kext updates will be made.

EFI folder based on [OpenCore](https://github.com/acidanthera/OpenCorePkg) for Asus ROG MAXIMUS Z790 DARK HERO, Intel Core i9-14900K and Asus Radeon RX 6900 XT.

Last tested with [macOS Sequoia](https://www.apple.com/macos/macos-sequoia/) `15.2` (`24C101`) with FileVault 2 enabled,
[Windows 11](https://www.microsoft.com/en-us/windows/windows-11) and [Manjaro Linux](https://manjaro.org/).

## Usage

- Clone this repository, and change directory there.
- Run `make release` to generate the `EFI` folder in `out/EFI` (see [manual testing](docs/contribution.md#manual-testing) for details).
- Follow the [replace placeholders](docs/contribution.md#replace-placeholders) section.
- Once done, mount the EFI partition and copy the `out/EFI` folder there.

## Hardware

Please refer to [hardware](docs/hardware.md) for detailed component specifications and [known issues](docs/known-issues.md) for compatibility information and
workarounds.

## Further details

Please refer to [OpenCore configuration](docs/opencore.md) and [BIOS settings](docs/bios.md).

## Contributing

Please refer to [contribution guide](docs/contribution.md) for the reference.

## Code of Conduct

Please refer to [Code of Conduct](CODE_OF_CONDUCT.md) for the reference.
