#!/usr/bin/env bash
#
# This script downloads OpenCore, associated kexts, and additional tools,
# then extracts and organizes them into the required EFI folder structure.
# It relies on configuration from build.env and helper functions from helpers.sh.

set -euo pipefail
shopt -s dotglob

# realpath is bundled in macOS Sequoia 15.2 (24C101) (Darwin 24.2.0),
# may need 'brew install coreutils' on older macOS versions.
BASE_DIR="$(dirname "$(realpath "$0")")"
readonly BASE_DIR

# Source helper functions.
source "${BASE_DIR}/helpers.sh"

# Ensure required utilities are installed.
for cmd in curl unzip hdiutil; do
  if ! command -v "$cmd" >/dev/null; then
    log_fail "Required command '${cmd}' is not installed."
  fi
done

# Set DEBUG mode and corresponding options.
DEBUG=${DEBUG:-false}
DEBUG=${DEBUG,,}
readonly DEBUG
if [[ "${DEBUG}" == "true" ]]; then
  CP_OPTS="-v"
  RM_OPTS="-v"
  MKDIR_OPTS="-v"
else
  CP_OPTS=""
  RM_OPTS=""
  MKDIR_OPTS=""
fi
log_info "DEBUG mode: ${DEBUG}"

# Source version and URL configuration.
source "${BASE_DIR}/build.env"
log_info "EFI package variant: ${EFI_VARIANT}."

# Define output directories.
BUILD_DIR="${BUILD_DIR:-${BASE_DIR}/out/EFI}"
readonly BUILD_DIR
BIN_DIR="${BIN_DIR:-${BASE_DIR}/out/bin}"
readonly BIN_DIR
KEXTS_DIR="${BUILD_DIR}/OC/Kexts"
readonly KEXTS_DIR

# Remove any existing build directory.
log_info "Ensuring empty build directory: ${BUILD_DIR}"
rm ${RM_OPTS} -rf "${BUILD_DIR}"

# Create a temporary directory for downloads.
TMP_DIR="$(mktemp -d)"
readonly TMP_DIR

# Cleanup function to remove temporary files on exit.
function cleanup() {
  local -ir exit_code=$?
  log_info "Cleaning up temporary directory: ${TMP_DIR}"
  rm -rf "${TMP_DIR}"
  if [[ $exit_code -ne 0 ]]; then
    log_info "Non-zero status code (${exit_code}) encountered, removing build directory: ${BUILD_DIR}"
    rm -rf "${BUILD_DIR}"
  fi
}
trap 'cleanup' EXIT SIGHUP SIGINT SIGQUIT SIGPIPE SIGTERM
log_info "Using temporary directory: ${TMP_DIR}"

# Download a file from a URL and unzips it into a destination.
# Arguments:
#   $1 - URL to download
#   $2 - Destination directory for the unzipped content
# Globals: MKDIR_OPTS, RM_OPTS, TMP_DIR
function download_and_unzip() {
  local -r url="$1"
  local -r dest="$2"

  log_info "Downloading: ${url}"
  curl -LSs --fail-with-body "${url}" --output "${TMP_DIR}/archive.zip"

  log_info "Unzipping to: ${dest}"
  mkdir ${MKDIR_OPTS} -p "${dest}"
  if ! unzip -q "${TMP_DIR}/archive.zip" -d "${dest}"; then
    log_fail "Failed to unzip archive from: ${url}"
  fi
  rm ${RM_OPTS} -f "${TMP_DIR}/archive.zip"
}

# Download, unzip, and copy a kext to the KEXTS_DIR.
# Arguments:
#   $1 - URL of the kext archive
#   $2 - Temporary directory to unzip the kext into
#   $3 - Name of the kext (without the .kext extension)
# Globals: CP_OPTS, KEXTS_DIR
function download_and_copy_kext() {
  local -r kext_url="$1" kext_tmp_dir="$2" kext_name="$3"
  download_and_unzip "${kext_url}" "${kext_tmp_dir}"
  log_info "Copying ${kext_name} to ${KEXTS_DIR}"
  cp ${CP_OPTS} -r "${kext_tmp_dir}/${kext_name}.kext" "${KEXTS_DIR}/"
}

# Mount an image file to a mount point, execute a function, then unmount.
# Arguments:
#   $1 - Image file path
#   $2 - Mount point directory
#   $3 - Function name to execute while the image is mounted
function with_mount() {
  local img_file="$1"
  local mount_point="$2"
  shift 2
  log_info "Mounting ${img_file} to ${mount_point}"
  hdiutil attach -quiet -readonly -noautoopen -mountpoint "${mount_point}" "${img_file}"
  "$@"
  log_info "Unmounting ${mount_point}"
  hdiutil detach -quiet "${mount_point}"
}

# Download MemTest86, mount its image, and copy required files.
# Globals: BUILD_DIR, CP_OPTS, MEMTEST_URL, TMP_DIR
function download_and_copy_memtest() {
  download_and_unzip "${MEMTEST_URL}" "${TMP_DIR}/MemTest86"

  local -r img_file="${TMP_DIR}/MemTest86/memtest86-usb.img"
  if [[ ! -f "${img_file}" ]]; then
    log_fail "${img_file} not found after unzipping."
  fi

  # Function to run while the image is mounted.
  function do_memtest_copy() {
    log_info "Copying files from mounted volume"
    cp ${CP_OPTS} "${TMP_DIR}/MemTest86/img/EFI/BOOT/BOOTX64.efi" "${BUILD_DIR}/OC/Tools/mt86/mt86.efi"
    cp ${CP_OPTS} "${TMP_DIR}/MemTest86/img/EFI/BOOT/"{blacklist.cfg,mt86.png,unifont.bin} "${BUILD_DIR}/OC/Tools/mt86/"
  }

  with_mount "${img_file}" "${TMP_DIR}/MemTest86/img" do_memtest_copy
}

# Start the ball (main build process).

# Create base folder structure.
log_info "Create base OpenCore folder structure and binary folder"
declare -ar dirs=(
  "${BUILD_DIR}/BOOT"
  "${BUILD_DIR}/OC/"{ACPI,Drivers,Kexts}
  "${BUILD_DIR}/OC/Resources/"{Audio,Font,Image,Label}
  "${BUILD_DIR}/OC/Resources/Image/Acidanthera/GoldenGate" # we will only copy Acidanthera/GoldenGate theme
  "${BUILD_DIR}/OC/Tools/mt86"
  "${BIN_DIR}"
)
for d in "${dirs[@]}"; do
  mkdir ${MKDIR_OPTS} -p "${d}"
done

# Download and install OpenCore.
log_info "Download OpenCore and copy essential binaries"
download_and_unzip "${OPENCORE_URL}" "${TMP_DIR}/OpenCorePkg"
cp ${CP_OPTS} "${TMP_DIR}/OpenCorePkg/X64/EFI/BOOT/"* "${BUILD_DIR}/BOOT/"
cp ${CP_OPTS} "${TMP_DIR}/OpenCorePkg/X64/EFI/OC/"{.content*,OpenCore.efi} "${BUILD_DIR}/OC/"
cp ${CP_OPTS} "${TMP_DIR}/OpenCorePkg/X64/EFI/OC/Drivers/"{AudioDxe,CrScreenshotDxe,OpenCanopy,OpenLinuxBoot,OpenRuntime,ResetNvramEntry,ToggleSipEntry}.efi \
  "${BUILD_DIR}/OC/Drivers/"
cp ${CP_OPTS} "${TMP_DIR}/OpenCorePkg/X64/EFI/OC/Tools/"{CleanNvram,OpenControl,OpenShell,ResetSystem}.efi "${BUILD_DIR}/OC/Tools/"
cp ${CP_OPTS} "${TMP_DIR}/OpenCorePkg/Utilities/ocvalidate/ocvalidate" "${BIN_DIR}/"

# Download and install OcBinaryData resources.
log_info "Download and copy OcBinaryData (Drivers and Resources)"
download_and_unzip "${OPENCORE_BINDATA_URL}" "${TMP_DIR}/OcBinaryData"
cp ${CP_OPTS} "${TMP_DIR}/OcBinaryData/OcBinaryData-master/Resources/Audio/"{AXEFIAudio_Beep,AXEFIAudio_Click,AXEFIAudio_VoiceOver_Boot,OCEFIAudio_VoiceOver_Boot}.mp3 \
  "${BUILD_DIR}/OC/Resources/Audio/"
cp ${CP_OPTS} "${TMP_DIR}/OcBinaryData/OcBinaryData-master/Drivers/"{HfsPlus,ext4_x64}.efi "${BUILD_DIR}/OC/Drivers/"
cp ${CP_OPTS} "${TMP_DIR}/OcBinaryData/OcBinaryData-master/Resources/Font/"* "${BUILD_DIR}/OC/Resources/Font/"
# Copy only the GoldenGate theme.
cp ${CP_OPTS} -r "${TMP_DIR}/OcBinaryData/OcBinaryData-master/Resources/Image/Acidanthera/GoldenGate/"* "${BUILD_DIR}/OC/Resources/Image/Acidanthera/GoldenGate/"
cp ${CP_OPTS} "${TMP_DIR}/OcBinaryData/OcBinaryData-master/Resources/Label/"* "${BUILD_DIR}/OC/Resources/Label/"

# Download and install kexts.
log_info "Download and extract all kexts, copy them to Kexts folder"
declare -Ar kexts=(
  ["AppleALC"]="${APPLEALC_URL}"
  ["CPUFriend"]="${CPUFRIEND_URL}"
  ["Lilu"]="${LILU_URL}"
  ["NVMeFix"]="${NVMEFIX_URL}"
  ["RestrictEvents"]="${RESTRICTEVENTS_URL}"
  ["SMCRadeonSensors"]="${SMCRADEONSENSORS_URL}"
  ["WhateverGreen"]="${WHATEVERGREEN_URL}"
)
for kext in "${!kexts[@]}"; do
  download_and_copy_kext "${kexts[$kext]}" "${TMP_DIR}/${kext}" "$kext"
done

# Handle special case for VirtualSMC (multiple kexts).
log_info "Downloading and extracting VirtualSMC kexts"
download_and_unzip "${VIRTUALSMC_URL}" "${TMP_DIR}/VirtualSMC"
cp ${CP_OPTS} -r "${TMP_DIR}/VirtualSMC/Kexts/"{SMCProcessor.kext,SMCSuperIO.kext,VirtualSMC.kext} "${KEXTS_DIR}/"

# Copy hardware-specific items (ACPI, custom kexts).
log_info "Copying hardware-specific items (ACPI, custom kexts, config.plist template)"
cp ${CP_OPTS} -r "${BASE_DIR}/efi/OC/ACPI/"*.aml "${BUILD_DIR}/OC/ACPI/"
cp ${CP_OPTS} -r "${BASE_DIR}/efi/OC/Kexts/"*.kext "${KEXTS_DIR}/"

# Download and install MemTest86.
log_info "Download and copy MemTest86 to Tools folder"
download_and_copy_memtest

# TODO(vovinacci): Implement placeholder replacements in config.plist.tmpl using awk.
# Example:
# awk -v boardsn="$BOARDSERIAL" -v mac="$MACADDRESS" -v serial="$SERIAL" -v smuuid="$SMUUID" \
# '{
#   gsub("{{ BOARDSERIAL }}", boardsn);
#   gsub("{{ MACADDRESS }}", mac);
#   gsub("{{ SERIAL }}", serial);
#   gsub("{{ SMUUID }}", smuuid);
#   print;
# }' "${BUILD_DIR}/OC/config.plist.tmpl" > "${BUILD_DIR}/OC/config.plist"
#
# # Validate the OpenCore configuration.
# log_info "Validating OpenCore ${OPENCORE_VERSION} configuration"
# if ! "${BIN_DIR}/ocvalidate" "${BUILD_DIR}/OC/config.plist"; then
#   log_fail "OpenCore configuration validation failed"
# fi

log_info "Build complete. Final EFI folder at: ${BUILD_DIR}"

# EOF
