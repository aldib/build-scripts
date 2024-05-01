LIBS_DIR=${LIBS_DIR:-$(dirname $0)}

source ${LIBS_DIR}/utils.sh

if [ -f ${CONFIG_FILE} ]; then
    log_debug "Loading configuration file ${CONFIG_FILE}"
    source ${CONFIG_FILE}
else
    log_error "Configuration file ${CONFIG_FILE} not found. Exiting."
    exit 1
fi

VALID_ARGS=$(getopt -o t:f:l: --long required-tools:,feature-flag:,file-filters: -- "$@")
if [[ $? -ne 0 ]]; then
    exit 1;
fi
eval set -- "$VALID_ARGS"

while [ : ]; do
  case "$1" in
    -f | --feature-flag)
        feature_flag=${2}
        if ! is_feature ${feature_flag} "enabled"; then
            log_debug "Feature \"${feature_flag}\" is not active. Ignoring this handler"
            exit 0;
        fi
        shift 2
        ;;  
    -t | --required-tools)
        required_tools=${2}
        shift 2
        ;;
    -l | --file-filters)
        file_filters=${2}
        shift 2
        ;;
    --) shift; 
        break 
        ;;
  esac
done

log_info "Looking for required tools: ${required_tools}"
for tool in ${required_tools//,/ }; do        
    tool_bin=$(find_tool ${tool})

    if [ -z ${tool_bin} ]; then        
        if is_feature ${feature_flag} "enforced"; then
            log_error "Tool '${tool}' is required but not found. Failing this handler"
            exit -1
        else
            log_debug "Tool '${tool}' is required but not found. Ignoring this handler"
            exit 0;
        fi
    else
        log_debug "Tool '${tool}' found and dynamically setting ${tool^^}_BIN=${tool_bin}"
        declare ${tool^^}_BIN=${tool_bin}                
    fi
done

if [ -v file_filters ]; then
    filtered_files=()
    for file in $@; do
        for filter in ${file_filters//,/ }; do
            if [[ ${file} =~ ${filter} ]]; then
                log_debug "${file} matches ${filter}. We'll keep it"
                filtered_files+=("${file}")
                break
            else
                log_trace "${file} did not match ${filter}. We'll ignore it"
            fi
        done
    done
    changed_files=${filtered_files[@]}
else
    changed_files=$@
fi

echo "////////////////////////////////" $changed_files