#!/usr/bin/env bash
#
# build.sh: Script to download OpenCore, Kexts, etc. and create EFI folder.

set -euo pipefail
shopt -s dotglob

# realpath is bundled in macOS Sequoia 15.2 (24C101) (Darwin 24.2.0),
# may need 'brew install coreutils' on older macOS versions.
BASE_DIR="$(dirname "$(realpath "$0")")"
readonly BASE_DIR

# Configuration / Versions
# All helper functions (e.g. log_info, fail) are sourced from a helpers.sh
source "${BASE_DIR}/helpers.sh"

DEBUG=${DEBUG:-false}
readonly DEBUG
if [[ "$DEBUG" == "true" ]]; then
  CP_OPTS="-v"
  RM_OPTS="-v"
  MKDIR_OPTS="-v"
else
  CP_OPTS=""
  RM_OPTS=""
  MKDIR_OPTS=""
fi
log_info "DEBUG mode: ${DEBUG}"

# Use release or debug variant
EFI_VARIANT=${EFI_VARIANT:-RELEASE}
readonly EFI_VARIANT
if ! [[ $EFI_VARIANT =~ ^(DEBUG|RELEASE)$ ]]; then
  log_fail "Unsupported EFI package variant: ${EFI_VARIANT}. Must be either DEBUG or RELEASE."
fi
log_info "EFI package variant: ${EFI_VARIANT}."

# All version variables are sourced from a build.env
source "${BASE_DIR}/build.env"

# Prepare environment
# final output directory
BUILD_DIR="${BUILD_DIR:-${BASE_DIR}/out/EFI}"
readonly BUILD_DIR
log_info "Ensuring empty build directory: ${BUILD_DIR}"
rm ${RM_OPTS} -rf "${BUILD_DIR}"

# Other directories
# Kexts directory in the final output directory
readonly KEXTS_DIR="${BUILD_DIR}/OC/Kexts"
# Directory for various helper binaries (e.g. ocvalidate)
BIN_DIR="${BIN_DIR:-${BASE_DIR}/out/bin}"
readonly BIN_DIR

# Temporary directory
TMP_DIR="$(mktemp -d)"
readonly TMP_DIR
# Keep environment clean
function run-on-trap() {
  log_info "Removing temporary directory '${TMP_DIR}'..."
  rm -rf "${TMP_DIR}"
  if [[ $1 -ne 0 ]]; then
    log_info "Non-zero status code ($1), removing build directory: ${BUILD_DIR}"
    rm -rf "${BUILD_DIR}"
  fi
}
trap 'run-on-trap $?' EXIT SIGHUP SIGINT SIGQUIT SIGPIPE SIGTERM
log_info "Using temporary directory: ${TMP_DIR}"

# Download from URL and unzip contents to the destination folder.
# Globals:
#   TMP_DIR
function download_and_unzip() {
  local -r url="$1"
  local -r dest="$2"

  log_info "Downloading: $url"
  curl -LSs --fail-with-body "$url" --output "${TMP_DIR}/archive.zip"

  log_info "Unzipping to: $dest"
  mkdir ${MKDIR_OPTS} -p "${dest}"
  unzip -q "${TMP_DIR}/archive.zip" -d "${dest}"
  rm ${RM_OPTS} -f "${TMP_DIR}/archive.zip"
}

# Download and copy Kexts to KEXTS_DIR
# Globals
#   KEXTS_DIR
function download_and_copy_kext() {
  local kext_url="$1"
  local kext_tmp_dir="$2"
  local kext_name="$3"

  download_and_unzip "$kext_url" "$kext_tmp_dir"
  log_info "Copying $kext_name to ${KEXTS_DIR}"
  cp ${CP_OPTS} -r "${kext_tmp_dir}/${kext_name}.kext" "${KEXTS_DIR}/"
}

# Download and copy MemTest86
# Globals
#   BUILD_DIR
#   MEMTEST_URL
#   TMP_DIR
function download_and_copy_memtest() {
  download_and_unzip "${MEMTEST_URL}" "${TMP_DIR}/MemTest86"

  local -r img_file="${TMP_DIR}/MemTest86/memtest86-usb.img"
  if [[ ! -f "$img_file" ]]; then
    log_fail "$img_file not found after unzipping."
  fi

  log_info "Mounting $img_file"
  local -r mount_point="${TMP_DIR}/MemTest86/img"
  hdiutil attach -quiet -readonly -noautoopen -mountpoint "${mount_point}" "${img_file}"
  trap 'log_info "Unmounting ${img_file}"; hdiutil detach -quiet "${mount_point}"' RETURN

  log_info "Copying files from mounted volume: ${mount_point}"
  cp ${CP_OPTS} "${mount_point}/EFI/BOOT/BOOTX64.efi" "${BUILD_DIR}/OC/Tools/mt86/mt86.efi"
  cp ${CP_OPTS} "${mount_point}/EFI/BOOT/"{blacklist.cfg,mt86.png,unifont.bin} "${BUILD_DIR}/OC/Tools/mt86/"
}

# Start the ball
log_info "Create base OpenCore folder structure and binary folder"
dirs=(
  "${BUILD_DIR}/BOOT"
  "${BUILD_DIR}/OC/ACPI"
  "${BUILD_DIR}/OC/Drivers"
  "${BUILD_DIR}/OC/Kexts"
  "${BUILD_DIR}/OC/Tools/mt86"
  "${BUILD_DIR}/OC/Resources/Audio"
  "${BUILD_DIR}/OC/Resources/Font"
  "${BUILD_DIR}/OC/Resources/Image"
  "${BUILD_DIR}/OC/Resources/Label"
  "${BUILD_DIR}/OC/Resources/Image/Acidanthera/GoldenGate" # we will only copy Acidanthera/GoldenGate theme
  "${BIN_DIR}/"
)
for d in "${dirs[@]}"; do
  mkdir ${MKDIR_OPTS} -p "$d"
done

log_info "Download OpenCore and copy essential binaries"
download_and_unzip "${OPENCORE_URL}" "${TMP_DIR}/OpenCorePkg"
cp ${CP_OPTS} "${TMP_DIR}/OpenCorePkg/X64/EFI/BOOT/"* "${BUILD_DIR}/BOOT/"
cp ${CP_OPTS} "${TMP_DIR}/OpenCorePkg/X64/EFI/OC/"{.content*,OpenCore.efi} "${BUILD_DIR}/OC/"
cp ${CP_OPTS} "${TMP_DIR}/OpenCorePkg/X64/EFI/OC/Drivers/"{AudioDxe,CrScreenshotDxe,OpenCanopy,OpenLinuxBoot,OpenRuntime,ResetNvramEntry,ToggleSipEntry}.efi \
  "${BUILD_DIR}/OC/Drivers/"
cp ${CP_OPTS} "${TMP_DIR}/OpenCorePkg/X64/EFI/OC/Tools/"{CleanNvram,OpenControl,OpenShell,ResetSystem}.efi "${BUILD_DIR}/OC/Tools/"
cp ${CP_OPTS} "${TMP_DIR}/OpenCorePkg/Utilities/ocvalidate/ocvalidate" "${BIN_DIR}/"

log_info "Download and copy OcBinaryData (Drivers and Resources)"
download_and_unzip "${OPENCORE_BINDATA_URL}" "${TMP_DIR}/OcBinaryData"
cp ${CP_OPTS} "${TMP_DIR}/OcBinaryData/OcBinaryData-master/Resources/Audio/"{AXEFIAudio_Beep,AXEFIAudio_Click,AXEFIAudio_VoiceOver_Boot,OCEFIAudio_VoiceOver_Boot}.mp3 \
  "${BUILD_DIR}/OC/Resources/Audio/"
cp ${CP_OPTS} "${TMP_DIR}/OcBinaryData/OcBinaryData-master/Drivers/"{HfsPlus,ext4_x64}.efi "${BUILD_DIR}/OC/Drivers/"
cp ${CP_OPTS} "${TMP_DIR}/OcBinaryData/OcBinaryData-master/Resources/Font/"* "${BUILD_DIR}/OC/Resources/Font/"
# we only copy GoldenGate theme
cp ${CP_OPTS} -r "${TMP_DIR}/OcBinaryData/OcBinaryData-master/Resources/Image/Acidanthera/GoldenGate/"* "${BUILD_DIR}/OC/Resources/Image/Acidanthera/GoldenGate/"
cp ${CP_OPTS} "${TMP_DIR}/OcBinaryData/OcBinaryData-master/Resources/Label/"* "${BUILD_DIR}/OC/Resources/Label/"

log_info "Download and extract all kexts, copy them to Kexts folder"

declare -A kexts=(
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

# Handle special case
# VirtualSMC has multiple kexts in 'Kexts/' subdir
download_and_unzip "${VIRTUALSMC_URL}" "${TMP_DIR}/VirtualSMC"
cp ${CP_OPTS} -r "${TMP_DIR}/VirtualSMC/Kexts/"{SMCProcessor.kext,SMCSuperIO.kext,VirtualSMC.kext} "${KEXTS_DIR}/"

log_info "Copying hardware-specific items (ACPI, custom kexts, config.plist template)"
cp ${CP_OPTS} -r "${BASE_DIR}/efi/OC/ACPI/"*.aml "${BUILD_DIR}/OC/ACPI/"
cp ${CP_OPTS} -r "${BASE_DIR}/efi/OC/Kexts/"*.kext "${KEXTS_DIR}/"
cp ${CP_OPTS} "${BASE_DIR}/efi/OC/config.plist" "${BUILD_DIR}/OC/"

log_info "Download and copy MemTest86 to Tools folder"
download_and_copy_memtest

# TODO(vovinacci): Do a placeholder replacements in config.plist if needed
# awk -v boardsn="$BOARDSERIAL" \
#     -v mac="$MACADDRESS" \
#     -v serial="$SERIAL" \
#     -v smuuid="$SMUUID" \
# '{
#   gsub("{{ BOARDSERIAL }}", boardsn);
#   gsub("{{ MACADDRESS }}", mac);
#   gsub("{{ SERIAL }}", serial);
#   gsub("{{ SMUUID }}", smuuid);
#   print;
# }' "${BUILD_DIR}/OC/config.plist" > "${BUILD_DIR}/OC/config.plist.tmp"
#
# mv ${MV_OPTS} "${BUILD_DIR}/OC/config.plist.tmp" "${BUILD_DIR}/OC/config.plist"

log_info "Validating OpenCore ${OPENCORE_VERSION} configuration"
"${BIN_DIR}/ocvalidate" "${BUILD_DIR}/OC/config.plist"

log_info "Build complete. Final EFI folder at: ${BUILD_DIR}"

# EOF
