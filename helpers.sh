#!/usr/bin/env bash

# Helper Functions
#
# Print error message to stderr and exit with status code 1.
# Arguments:
#   Error message
function log_fail() {
  echo >&2 "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ERROR: $*"
  exit 1
}

# Print an INFO-level log message with timestamp
# Arguments:
#   Log message
function log_info() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] INFO: $*"
}

# EOF
