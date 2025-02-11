# Contribution guide

This document provides guidelines for contributing to the toolkit.

1. Install required software (see [Dependencies](#dependencies)).
2. Make changes, ensure [linting and unit testing](#linting-and-unit-testing) and [manual testing](#manual-testing), then commit.

   Initial commit messages should follow the [Conventional Commits](https://www.conventionalcommits.org/) style (e.g. `feat(opencore): add new driver`).
3. Send a pull request with your changes.
4. A maintainer will review the pull request and make comments.

   Prefer adding additional commits over amending and force-pushing, since it can be difficult to follow code reviews when the commit history changes.

   Commits will be squashed when they're merged.

## Dependencies

Full list of dependencies could be installed with [Homebrew](https://brew.sh/):

```shell
brew bundle --file ./ci/Brewfile
```

## Linting and unit testing

Many of the files in the repository can be linted and unit tests can be run to maintain a standard of quality.

Run `make lint test`.

## Manual testing

To download all necessary packages and extract files to the `out/EFI` folder in the current directory, run the following commands.

To generate an EFI folder in `out/EFI`, run:

- DEBUG variant: `make debug`
- RELEASE variant: `make release`

Once done, follow [replace placeholders](#replace-placeholders), mount the EFI partition and copy the `out/EFI` folder there.

## Replace placeholders

Two things to be done manually before moving everything to the actual EFI partition:

- Replace `{{ SERIAL }}`, `{{ BOARDSERIAL }}` and `{{ SMUUID }}` with actual values in `out/EFI/OC/config.plist`.

  If you don't have one, a great example of how to do this could be found
  [here](https://dortania.github.io/OpenCore-Post-Install/universal/iservices.html).
- Replace `{{ MACADDRESS }}` with the actual `en0` MAC address value in `out/EFI/OC/config.plist`.

  Another great example on how to do it is [here](https://dortania.github.io/OpenCore-Post-Install/universal/iservices.html#fixing-en0).
