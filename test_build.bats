#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2076,SC2155
#
# These tests verify that the build.sh script creates a functional EFI folder
# structure under various modes (RELEASE, DEBUG) and fails under invalid settings.
#
# Notes:
#   - This file uses Bats (https://github.com/bats-core/bats-core) for testing.
#   - The build script is expected to output the final EFI folder to a directory
#     referenced by the BUILD_DIR environment variable.

# Print an error to stderr and return exit code 1, triggering a test failure.
function fail() {
  echo "$@" >&2
  return 1
}

# Utility Functions to Generate Unique Directories.
#   Each test has its own unique bin/ and build/ directories, preventing
#   interference between parallel or sequential runs. These directories are
#   removed in the teardown() function.
function unique_bin_dir() {
  echo "${BATS_TEST_DIRNAME}/out/test_bin_${BATS_TEST_NUMBER}"
}

function unique_build_dir() {
  echo "${BATS_TEST_DIRNAME}/out/test_efi_${BATS_TEST_NUMBER}"
}

# After each test, remove the directories used by that test to ensure a clean environment for subsequent tests.
function teardown() {
  # Clean again after each test
  rm -rf "$THIS_TEST_BUILD_DIR" "$THIS_TEST_BIN_DIR"
}

# A helper function that accepts a "prefix" directory (our build directory) and a list of expected relative paths.
# If any of the paths do not exist under the prefix, the test fails.
function check_expected_files_exist() {
  local -r prefix="$1"
  shift
  local missing=()

  # For each required path, verify that it actually exists in 'prefix'.
  for path in "$@"; do
    if [ ! -e "$prefix/$path" ]; then
      missing+=("$path")
    fi
  done

  # If any required paths are missing, output them and fail the test.
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "Missing expected file(s):"
    for m in "${missing[@]}"; do
      echo "  - $m"
    done
    fail "One or more required files/directories are missing."
  fi
}

# We define an array of all files/directories that must exist after a successful build.

# EXPECTED_PATHS Array
#   We export this Bash array so that it is properly recognized within Bats.
#   It lists all the files and folders we expect to exist after a successful
#   build. If any are missing, the test will fail.
export EXPECTED_PATHS=(
  # Top-level folders/files
  "BOOT"
  "BOOT/.contentFlavour"
  "BOOT/.contentVisibility"
  "BOOT/BOOTx64.efi"

  # OC root
  "OC"
  "OC/.contentFlavour"
  "OC/.contentVisibility"
  "OC/OpenCore.efi"

  # ACPI
  "OC/ACPI"
  "OC/ACPI/SSDT-EC.aml"
  "OC/ACPI/SSDT-PLUG-ALT.aml"
  "OC/ACPI/SSDT-RTCAWAC.aml"
  "OC/ACPI/SSDT-SBUS-MCHC.aml"
  "OC/ACPI/SSDT-USBX.aml"

  # Drivers
  "OC/Drivers"
  "OC/Drivers/AudioDxe.efi"
  "OC/Drivers/CrScreenshotDxe.efi"
  "OC/Drivers/HfsPlus.efi"
  "OC/Drivers/OpenCanopy.efi"
  "OC/Drivers/OpenLinuxBoot.efi"
  "OC/Drivers/OpenRuntime.efi"
  "OC/Drivers/ResetNvramEntry.efi"
  "OC/Drivers/ToggleSipEntry.efi"
  "OC/Drivers/ext4_x64.efi"

  # Kexts
  "OC/Kexts"
  "OC/Kexts/AppleALC.kext"
  "OC/Kexts/CPUFriend.kext"
  "OC/Kexts/CPUFriendDataProvider.kext"
  "OC/Kexts/Lilu.kext"
  "OC/Kexts/NVMeFix.kext"
  "OC/Kexts/RestrictEvents.kext"
  "OC/Kexts/SMCProcessor.kext"
  "OC/Kexts/SMCRadeonSensors.kext"
  "OC/Kexts/SMCSuperIO.kext"
  "OC/Kexts/USBMap.kext"
  "OC/Kexts/VirtualSMC.kext"
  "OC/Kexts/WhateverGreen.kext"

  # Resources
  "OC/Resources"
  "OC/Resources/Audio"
  "OC/Resources/Font"
  "OC/Resources/Image"
  "OC/Resources/Label"

  # Tools
  "OC/Tools"
  "OC/Tools/CleanNvram.efi"
  "OC/Tools/OpenControl.efi"
  "OC/Tools/OpenShell.efi"
  "OC/Tools/ResetSystem.efi"
  "OC/Tools/mt86"
  "OC/Tools/mt86/blacklist.cfg"
  "OC/Tools/mt86/mt86.efi"
  "OC/Tools/mt86/mt86.png"
  "OC/Tools/mt86/unifont.bin"
)

# ------------------------------------------------------------------------
# Tests
# ------------------------------------------------------------------------

@test "Build script runs successfully in default (RELEASE) mode" {
  # Generate unique directories for this test.
  export THIS_TEST_BIN_DIR="$(unique_bin_dir)"
  export THIS_TEST_BUILD_DIR="$(unique_build_dir)"

  export BIN_DIR="$THIS_TEST_BIN_DIR"
  export BUILD_DIR="$THIS_TEST_BUILD_DIR"

  # Assert that the build script exited successfully (0).
  run ./build.sh
  [ "$status" -eq 0 ]

  # Check for relevant output in the script logs.
  [[ "$output" =~ "DEBUG mode: false" ]]
  [[ "$output" =~ "Build complete. Final EFI folder at:" ]]

  # Verify that all expected files/folders exist in the BUILD_DIR.
  check_expected_files_exist "${BUILD_DIR}" "${EXPECTED_PATHS[@]}"

  # Finally, check that ocvalidate exists and is executable in the BIN_DIR.
  [ -x "$THIS_TEST_BIN_DIR/ocvalidate" ] || fail "Missing ocvalidate in BIN_DIR"
}

@test "Build script runs successfully in DEBUG mode" {
  # Generate unique directories for this test.
  export THIS_TEST_BIN_DIR="$(unique_bin_dir)"
  export THIS_TEST_BUILD_DIR="$(unique_build_dir)"

  export BIN_DIR="$THIS_TEST_BIN_DIR"
  export BUILD_DIR="$THIS_TEST_BUILD_DIR"

  # The build script sets DEBUG to 'true' and normalizes the EFI_VARIANT.
  export DEBUG=true
  export EFI_VARIANT=DeBuG

  # Assert that the build script exited successfully (0).
  run ./build.sh
  [ "$status" -eq 0 ]

  # Check for relevant output in the script logs.
  [[ "$output" =~ "DEBUG mode: true" ]]
  [[ "$output" =~ "Build complete. Final EFI folder at:" ]]

  # Verify that all expected files/folders exist in the BUILD_DIR.
  check_expected_files_exist "${BUILD_DIR}" "${EXPECTED_PATHS[@]}"

  # Finally, check that ocvalidate exists and is executable in the BIN_DIR.
  [ -x "$THIS_TEST_BIN_DIR/ocvalidate" ] || fail "Missing ocvalidate in BIN_DIR"
}

@test "Build script fails with invalid EFI_VARIANT" {
  # Generate unique directories for this test.
  export THIS_TEST_BIN_DIR="$(unique_bin_dir)"
  export THIS_TEST_BUILD_DIR="$(unique_build_dir)"

  export BIN_DIR="$THIS_TEST_BIN_DIR"
  export BUILD_DIR="$THIS_TEST_BUILD_DIR"

  # The build script EFI_VARIANT to unacceptable value.
  export EFI_VARIANT="FOOBAR"

  # We expect the script to fail, so status should not be 0.
  run ./build.sh
  [ "$status" -ne 0 ]

  # Check for relevant output in the script logs.
  [[ "$output" =~ "Unsupported EFI package variant" ]]
}
