#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2076,SC2155

# It's assumed:
#  - The build outputs to ./out/EFI (relative to build.sh)

function fail() {
  echo "$@" >&2
  return 1
}

# Generate a unique bin directory for each test, based on $BATS_TEST_NUMBER.
function unique_bin_dir() {
  echo "${BATS_TEST_DIRNAME}/out/test_bin_${BATS_TEST_NUMBER}"
}

# Generate a unique build directory for each test, based on $BATS_TEST_NUMBER.
function unique_build_dir() {
  echo "${BATS_TEST_DIRNAME}/out/test_efi_${BATS_TEST_NUMBER}"
}

# Remove the test's unique build directory after each test
function teardown() {
  # Clean again after each test
  rm -rf "$THIS_TEST_BUILD_DIR" "$THIS_TEST_BIN_DIR"
}

# A helper function to check mandatory files (and directories) exist.
# If a file or directory is missing, the test will fail.
function check_expected_files_exist() {
  local -r prefix="$1"
  shift
  local missing=()
  for path in "$@"; do
    if [ ! -e "$prefix/$path" ]; then
      missing+=("$path")
    fi
  done

  # If any path is missing, produce a test failure.
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "Missing expected file(s):"
    for m in "${missing[@]}"; do
      echo "  - $m"
    done
    fail "One or more required files/directories are missing."
  fi
}

# We define an array of all files/directories that must exist after a successful build.
declare -a EXPECTED_PATHS=(
  # Top-level folders/files
  "out/EFI"
  "out/EFI/BOOT"
  "out/EFI/BOOT/.contentFlavour"
  "out/EFI/BOOT/.contentVisibility"
  "out/EFI/BOOT/BOOTx64.efi"

  # OC root
  "out/EFI/OC"
  "out/EFI/OC/.contentFlavour"
  "out/EFI/OC/.contentVisibility"
  "out/EFI/OC/OpenCore.efi"
  "out/EFI/OC/config.plist"

  # ACPI
  "out/EFI/OC/ACPI"
  "out/EFI/OC/ACPI/SSDT-EC.aml"
  "out/EFI/OC/ACPI/SSDT-PLUG-ALT.aml"
  "out/EFI/OC/ACPI/SSDT-RTCAWAC.aml"
  "out/EFI/OC/ACPI/SSDT-SBUS-MCHC.aml"
  "out/EFI/OC/ACPI/SSDT-USBX.aml"

  # Drivers
  "out/EFI/OC/Drivers"
  "out/EFI/OC/Drivers/AudioDxe.efi"
  "out/EFI/OC/Drivers/CrScreenshotDxe.efi"
  "out/EFI/OC/Drivers/HfsPlus.efi"
  "out/EFI/OC/Drivers/OpenCanopy.efi"
  "out/EFI/OC/Drivers/OpenLinuxBoot.efi"
  "out/EFI/OC/Drivers/OpenRuntime.efi"
  "out/EFI/OC/Drivers/ResetNvramEntry.efi"
  "out/EFI/OC/Drivers/ToggleSipEntry.efi"
  "out/EFI/OC/Drivers/ext4_x64.efi"

  # Kexts
  "out/EFI/OC/Kexts"
  "out/EFI/OC/Kexts/AppleALC.kext"
  "out/EFI/OC/Kexts/CPUFriend.kext"
  "out/EFI/OC/Kexts/CPUFriendDataProvider.kext"
  "out/EFI/OC/Kexts/Lilu.kext"
  "out/EFI/OC/Kexts/NVMeFix.kext"
  "out/EFI/OC/Kexts/RestrictEvents.kext"
  "out/EFI/OC/Kexts/SMCProcessor.kext"
  "out/EFI/OC/Kexts/SMCRadeonSensors.kext"
  "out/EFI/OC/Kexts/SMCSuperIO.kext"
  "out/EFI/OC/Kexts/USBMap.kext"
  "out/EFI/OC/Kexts/VirtualSMC.kext"
  "out/EFI/OC/Kexts/WhateverGreen.kext"

  # Resources
  "out/EFI/OC/Resources"
  "out/EFI/OC/Resources/Audio"
  "out/EFI/OC/Resources/Font"
  "out/EFI/OC/Resources/Image"
  "out/EFI/OC/Resources/Label"

  # Tools
  "out/EFI/OC/Tools"
  "out/EFI/OC/Tools/CleanNvram.efi"
  "out/EFI/OC/Tools/OpenControl.efi"
  "out/EFI/OC/Tools/OpenShell.efi"
  "out/EFI/OC/Tools/ResetSystem.efi"
  "out/EFI/OC/Tools/mt86"
  "out/EFI/OC/Tools/mt86/blacklist.cfg"
  "out/EFI/OC/Tools/mt86/mt86.efi"
  "out/EFI/OC/Tools/mt86/mt86.png"
  "out/EFI/OC/Tools/mt86/unifont.bin"
)

@test "Build script runs successfully in default (RELEASE) mode" {
  export THIS_TEST_BIN_DIR="$(unique_bin_dir)"
  export THIS_TEST_BUILD_DIR="$(unique_build_dir)"

  export BIN_DIR="$THIS_TEST_BIN_DIR"
  export BUILD_DIR="$THIS_TEST_BUILD_DIR"
  run ./build.sh

  [ "$status" -eq 0 ]
  [[ "$output" =~ "DEBUG mode: false" ]]
  [[ "$output" =~ "Build complete. Final EFI folder at:" ]]

  check_expected_files_exist "${BUILD_DIR}" "${EXPECTED_PATHS[@]}"
  [ -x "$THIS_TEST_BIN_DIR/ocvalidate" ] || fail "Missing ocvalidate in BIN_DIR"
}

@test "Build script runs successfully in DEBUG mode" {
  export THIS_TEST_BIN_DIR="$(unique_bin_dir)"
  export THIS_TEST_BUILD_DIR="$(unique_build_dir)"

  export BIN_DIR="$THIS_TEST_BIN_DIR"
  export BUILD_DIR="$THIS_TEST_BUILD_DIR"
  export DEBUG=true
  export EFI_VARIANT=DEBUG
  run ./build.sh

  [ "$status" -eq 0 ]
  [[ "$output" =~ "DEBUG mode: true" ]]
  [[ "$output" =~ "Build complete. Final EFI folder at:" ]]

  check_expected_files_exist "${BUILD_DIR}" "${EXPECTED_PATHS[@]}"
  [ -x "$THIS_TEST_BIN_DIR/ocvalidate" ] || fail "Missing ocvalidate in BIN_DIR"
}

@test "Build script fails with invalid EFI_VARIANT" {
  export THIS_TEST_BIN_DIR="$(unique_bin_dir)"
  export THIS_TEST_BUILD_DIR="$(unique_build_dir)"

  export BIN_DIR="$THIS_TEST_BIN_DIR"
  export BUILD_DIR="$THIS_TEST_BUILD_DIR"
  export EFI_VARIANT="FOOBAR"
  run ./build.sh

  [ "$status" -ne 0 ]
  [[ "$output" =~ "Unsupported EFI package variant" ]]
}
