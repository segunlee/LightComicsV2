#!/bin/bash
set -euo pipefail

if test -d "/opt/homebrew/bin/"; then
  PATH="/opt/homebrew/bin/:${PATH}"
fi

export PATH
CONFIG="$(dirname "$0")/.swiftformat" # 모든 모듈은 Script/ 아래에 있는 swiftformat파일을 사용한다.

if which swiftformat > /dev/null; then
  if ! swiftformat . --config "${CONFIG}"; then
  # if ! swiftformat . --config "${CONFIG}" --lint; then
    echo "error: SwiftFormat found formatting issues. Please fix them before building."
    exit 1
  fi
else
  echo "warning: SwiftFormat not installed, please run 'brew install swiftformat'"
fi
