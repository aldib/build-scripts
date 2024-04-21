
# /*!
#    Prints logging statement. The global logging level is set by the environment 
#    variable GIT_HOOK_LOG_LEVEL with a default of INFO
# 
#    @param $1 
#        the logging level
#    @param $2 
#        the message
#  */
function log {
    NC='\033[0m' # No Color

    function _parse_log_level {
        shopt -s nocasematch
        case ${1} in
            ("ERROR" | "0" | 0) echo 0;;
            ("INFO" | "1" | 1)  echo 1;;
            ("DEBUG" | "2" | 2) echo 2;;
            ("TRACE" | "3" | 3) echo 3;;
            (*)                 echo 1;;
        esac
        shopt -u nocasematch
    }

    local level_config=$(_parse_log_level ${GIT_HOOK_LOG_LEVEL:-INFO}) 

    if [ $# -ge 1 ];then
        local level="${1}"
        local level_num=$(_parse_log_level ${level})

        local log_colour=$(case ${level_num} in
            (0) echo '\033[0;31m';; #Red
            (1) echo '\033[0;34m';; #Blue
            (2) echo '\033[0;35m';; #Purple
            (3) echo '\033[0;32m';; #Green
            (*) echo '\033[0;30m';; #Black
        esac)

        if [ ${level_config} -ge ${level_num} ];then
            local message="${*:2}"
            # Logging to stderr so that functions can both log and return values
            printf "${log_colour}%(%F:%T)T.%06.0f [%s] (%s) %s\n${NC}" ${EPOCHREALTIME/./ } "${level}" ${0##*/} "${message}" >&2
        fi
    fi
}

# /*!
#    Prints logging statement with ERROR level
#    @param $1 
#        the message
#  */
function log_error {
    log "ERROR" $@
}

# /*!
#    Prints logging statement with INFO level
#    @param $1 
#        the message
#  */
function log_info {
    log "INFO" $@
}

# /*!
#    Prints logging statement with DEBUG level
#    @param $1 
#        the message
#  */
function log_debug {
    log "DEBUG" $@
}

# /*!
#    Prints logging statement with DEBUG level
#    @param $1 
#        the message
#  */
function log_trace {
    log "TRACE" $@
}


# /*!
#    This function checks if an environment variable has a value of true
#    @param $1 
#        the name of the environment variable to check
#    @param $2 
#        the optional default value if the environment variable 
#    @return 
#        0 if the the value is equal to 1 or true, or 1 otherwise
#        IMPORTANT: when returning exit codes, 0 = true, 1 = false. See https://tldp.org/LDP/abs/html/exitcodes.html#EXITCODESREF
#  */
function is_true {
    local name=${1}
    local exit_code=1

    # check if the variable is set
    if [ -v ${name} ]; then 
        local value=${!name}
    # if not and the default value was passed as a second parameter, we use it
    elif [[ $# -ge 2 ]]; then
        local value=${2}
    fi

    # if we have a value to compare    
    if [ -v value ]; then 
        shopt -s nocasematch
        if [[ "${value}" = true || "${value}" = "true" || "${value}" = 1 || "${value}" = "1" ]]; then    
            exit_code=0
        fi
        shopt -u nocasematch
    fi
    return ${exit_code}
}

function find_tool {
    local tool=${1}
    log_debug "Looking for ${tool}"

    local tool_path="${tool^^}_BIN"
    log_trace "Checking if ${tool_path} is defined"

    if [ -v ${tool_path} ]; then
        local tool_bin=${!tool_path}
        if [ -f ${tool_bin} ]; then
            log_debug "Found ${tool_bin} in PATH"
            echo ${tool_bin}
        else
            log_debug "${tool_bin} not found"
            return 1
        fi
    else
        log_trace "${tool_path} is not defined, checking PATH" 
        if command -v ${tool} &> /dev/null; then
            log_debug "Found ${tool} in PATH"
            echo ${tool}
        else
            log_debug "${tool} not found in PATH"
            return 1
        fi
    fi
}
