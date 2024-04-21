#!/usr/bin/env bash

# exit when a command fails.
set -o errexit
# exit when your script tries to use undeclared variables.
set -o nounset
# The exit status of the last command that threw a non-zero exit code is returned.
set -o pipefail

LIBS_DIR=${LIBS_DIR:-$(dirname $0)}

REQUIRED_TOOLS="terraform tflint"

TFLINT_BIN=/home/tflint

source ${LIBS_DIR}/base_handler.sh

log_info "test"

