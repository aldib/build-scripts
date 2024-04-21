# exit when a command fails.
set -o errexit
# exit when your script tries to use undeclared variables.
set -o nounset
# The exit status of the last command that threw a non-zero exit code is returned.
set -o pipefail

LIBS_DIR=${LIBS_DIR:-$(dirname $0)}

source ${LIBS_DIR}/utils.sh


if ! is_true "GIT_HOOKS_ENABLED" 1; then
    exit 0
fi

hook_type=${1}

handlers_dir=${PWD}/${hook_type}-handlers

log_info "Running scripts in ${handlers_dir}"

for script in ${handlers_dir}/*.sh; do
    script_name=$(basename ${script})
    log_debug "Running ${script_name}"
    if [[ ! -x "${script}" ]]
    then
        log_debug "Making ${script} executable"
        chmod u+x ${script}
    fi


    exec -c -a ${script_name} env LIBS_DIR=${LIBS_DIR} env GIT_HOOK_LOG_LEVEL=${GIT_HOOK_LOG_LEVEL:-INFO} ${script}
done