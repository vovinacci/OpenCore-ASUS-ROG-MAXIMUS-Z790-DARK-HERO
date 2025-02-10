# Contribution guide

TODO

## Replace placeholders

Two things to be done manually before moving everything to actual EFI partition:

- Replace `{{ SERIAL }}`, `{{ BOARDSERIAL }}` and `{{ SMUUID }}` with actual values in `out/EFI/OC/config.plist`.

  If you don't have one, great example on how to do this could be found
  [here](https://dortania.github.io/OpenCore-Post-Install/universal/iservices.html).
- Replace `{{ MACADDRESS }}` with actual `en0` MAC address value in `out/EFI/OC/config.plist`.

  Another great example on how to do it is [here](https://dortania.github.io/OpenCore-Post-Install/universal/iservices.html#fixing-en0).
