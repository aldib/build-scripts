
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



# /*!
#    This function checks if a tool is available. 
#    First it checks if the variable <TOOL_NAME_IN_CAPITAL_LETTERS>_BIN (e.g. GREP_BIN).
#    If yes, it verifies the value of the variable points to correct path for the tool.
#    If not, it look for the tool in the PATH.
#    @param $1 
#        the name of the tool
#    @return 
#        the path of the tool or an empty string if not found
#  */
function find_tool {
    local tool=${1}
    log_debug "Looking for ${tool}"

    local tool_path="${tool^^}_BIN"
    log_trace "Checking if ${tool_path} is defined"

    if [ -v ${tool_path} ]; then
        log_trace "${tool_path} is defined, and its value is ${!tool_path}"
        tool=${!tool_path}
    else
        log_trace "${tool_path} is not defined, checking PATH" 
    fi

    command -v -- ${tool} || echo ""
}


function is_feature {
    local exit_code=1 
    
    local flag="${1^^}_HOOKS"
    local expected_state=${2^^}

    case ${expected_state} in
        DISABLED|ENABLED|ENFORCED)
            # check if the flag variable is set
            if [ -v ${flag} ]; then 
                local current_state=${!flag}
                log_trace "Flag ${flag} is ${current_state^^}"
            fi
            if [ -v current_state ]; then 
                shopt -s nocasematch
                if [[ "${expected_state}" = "${current_state}" ]]; then   # they match
                    exit_code=0
                elif [[ "${expected_state}" = "ENABLED" && "${current_state}" = "ENFORCED" ]]; then   # they match
                    exit_code=0
                fi
                shopt -u nocasematch
            fi
            ;;
        *)
            log_error "${2^^} is not a valid value. Only DISABLED, ENABLED or ENFORCED are supported"
    esac

    return ${exit_code}
}