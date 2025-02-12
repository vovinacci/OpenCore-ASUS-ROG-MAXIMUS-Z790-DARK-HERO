#!/usr/bin/env bash
#
# This script provides basic logging functions with timestamps.
# It must be sourced before build.env and build.sh.

LOG_TS_FORMAT="+%Y-%m-%dT%H:%M:%S%z"
readonly LOG_TS_FORMAT

# Print an error message with a timestamp to stderr and exit.
# Arguments:
#   Message(s) describing the error.
function log_fail() {
  echo >&2 "[$(date "${LOG_TS_FORMAT}")] ERROR: $*"
  exit 1
}

# Prints an informational message with a timestamp to stdout.
# Arguments:
#   Message(s) to be logged.
function log_info() {
  echo "[$(date "${LOG_TS_FORMAT}")] INFO: $*"
}

# EOF
