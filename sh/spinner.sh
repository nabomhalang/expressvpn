#!/bin/bash

function _spinner() {
    case $1 in
        start)
            let column=$(tput cols)-${#2}-8
            echo -ne ${2}
            printf "%${column}s"

            sp='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
            i=0
            delay=${SPINNER_DELAY:-0.15}

            while :
            do
                # 스피너 회전
                printf "\b${sp:i++%${#sp}:1}"
                sleep $delay
            done
            ;;
        stop)
            if [[ -z ${3} ]]; then
                echo "Spinner is not running.."
                exit 1
            fi

            kill $3 > /dev/null 2>&1

            echo -en "\b${bold}["
            if [[ $2 -eq 0 ]]; then
                echo -en "${on_success}"
		echo -e "${bold}]${nc}"
            else
                echo -en "${on_fail}"
		echo -e "${bold}]${nc}"
            fi
            ;;
        *)
            echo "Invalid argument, try {start/stop}"
            exit 1
            ;;
    esac
}

function start_spinner {
    # 스피너 시작 함수
    _spinner "start" "${1}" &
    _sp_pid=$!
    disown
}

function stop_spinner {
    # 스피너 멈춤 함수
    _spinner "stop" "$1" "$_sp_pid" "$2"
    unset _sp_pid
}

