#!/bin/bash
set -euo pipefail

# Clear Xcode build environment variables that interfere with running
# a standalone Swift script (they cause it to target the wrong SDK).
unset SDKROOT
unset MACOSX_DEPLOYMENT_TARGET
unset IPHONEOS_DEPLOYMENT_TARGET

if ! swift "$(dirname "$0")/GenerateStrings.swift"; then
	echo "error: String generation failed."
	exit 1
fi
