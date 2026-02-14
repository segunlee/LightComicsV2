#!/bin/bash
set -euo pipefail

if test -d "/opt/homebrew/bin/"; then
	PATH="/opt/homebrew/bin/:${PATH}"
fi

export PATH
YML="$(dirname "$0")/.swiftlint.yml" # 모든 모듈은 Script/ 아래에 있는 린트파일을 사용한다.

if which swiftlint > /dev/null; then
	if ! swiftlint --config "${YML}"; then
		echo "error: SwiftLint found issues. Please fix them before building."
		exit 1
	fi
else
	echo "warning: SwiftLint not installed, please run 'brew install swiftlint'"
fi
