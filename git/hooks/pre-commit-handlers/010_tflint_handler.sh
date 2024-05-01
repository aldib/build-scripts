#!/usr/bin/env bash

# exit when a command fails.
set -o errexit
# exit when your script tries to use undeclared variables.
set -o nounset
# The exit status of the last command that threw a non-zero exit code is returned.
set -o pipefail

LIBS_DIR=${LIBS_DIR:-$(dirname $0)}
TFLINT_CONFIG=${TFLINT_CONFIG:-$(dirname $0)/.tflint.hcl}


source ${LIBS_DIR}/base_handler.sh --required-tools tflint --feature-flag terraform --file-filters 'tf$,tfvars$'  -- $@

${TFLINT_BIN} --chdir=${PROJECT_DIR} --config=${TFLINT_CONFIG} --init

for file in $changed_files; do
    log_info "Linting ${file}"
    ${TFLINT_BIN} --config=${TFLINT_CONFIG} --filter ${file}
done

