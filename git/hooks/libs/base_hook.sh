LIBS_DIR=${LIBS_DIR:-$(dirname $0)}
PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
CONFIG_FILE=${GITHOOKS_CONFIG:-${PROJECT_DIR}/.githooks.rc}

source ${LIBS_DIR}/utils.sh

if [ -f ${CONFIG_FILE} ]; then
    log_debug "Loading configuration file ${CONFIG_FILE}"
    source ${CONFIG_FILE}
else
    log_debug "Configuration file ${CONFIG_FILE} not found. Exiting."
    exit 0
fi

hook_type=${1}
shift

handlers_dir=${HOOKS_DIR}/${hook_type}-handlers

log_info "Running scripts in ${handlers_dir} with paramters $@"

if [[ $# -gt 0 ]] ; then
    log_debug "Using the list of changed files that was passed explicitly"
    changed_files=$@
else
    log_debug "Using git diff to find the list of changed files"
    changed_files=$(git diff --name-only --cached --diff-filter=ACMR)
fi

for script in ${handlers_dir}/*.sh; do
    script_name=$(basename ${script})
    log_debug "Running ${script_name}"
    if [[ ! -x "${script}" ]]
    then
        log_debug "Making ${script} executable"
        chmod u+x ${script}
    fi

    set +o errexit
    env -i \
        HOME=${HOME} \
        PROJECT_DIR=${PROJECT_DIR} \
        LIBS_DIR=${LIBS_DIR} \
        CONFIG_FILE=${CONFIG_FILE} \
        ${script} \
        ${changed_files};
    script_exit_code=${?}
    set -o errexit

    if [ ${script_exit_code} -ne 0 ]; then
        log_error "${script} failed with error ${script_exit_code}"
        exit -1
    else
        log_error "${script} completed successfully"
    fi
    
done