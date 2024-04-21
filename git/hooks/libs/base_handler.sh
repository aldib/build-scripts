# exit when a command fails.
set -o errexit
# exit when your script tries to use undeclared variables.
set -o nounset
# The exit status of the last command that threw a non-zero exit code is returned.
set -o pipefail

LIBS_DIR=${LIBS_DIR:-$(dirname $0)}

source ${LIBS_DIR}/utils.sh


if [ -v REQUIRED_TOOLS ]; then 
    log_info "Looking for required tools: ${REQUIRED_TOOLS}"
    for tool in ${REQUIRED_TOOLS}; do        
        tool_bin=$(find_tool ${tool})
        log_trace "${tool_bin} $?"
        if [ $? -ne 0 ]; then
            log_error "Tool '${tool}' is required but not found on the path"
            exit -1
        fi
    done
fi


# log_info "Looking for files to be committed in ${PWD}"
# changed_files=$(git diff --name-only --cached --diff-filter=ACMR)
