#!/bin/bash

function _spinner() {
    case $1 in
        start)
            let column=$(tput cols)-${#2}
            echo -ne ${2}
            printf "%${column}s"

            sp='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
            i=0
            delay=${SPINNER_DELAY:-0.15}

            # &로 돌리지 말고 바로 여기에 대기 중인 명령어 실행
            while :
            do
                printf "\b${sp:i++%${#sp}:1}"
                sleep $delay
            done &
            # Back up the PID so that we can kill the spinner process later
            echo $! > .spinner_pid
            ;;
        stop)
            if [[ -f .spinner_pid ]]; then
                # Kill spinner's background process using PID from file
                kill $(cat .spinner_pid) > /dev/null 2>&1
                rm .spinner_pid

                echo -en "\b${bold}["
                if [[ $2 -eq 0 ]]; then
                    echo -e "${on_success}${bold}]${nc}"
                else
                    echo -e "${on_fail}${bold}]${nc}"
                fi
            else
                echo "Spinner is not running.."
                exit 1
            fi
            ;;
        *)
            echo "Invalid argument, try {start/stop}"
            exit 1
            ;;
    esac
}

function start_spinner {
    _spinner "start" "${1}"
}

function stop_spinner {
    _spinner "stop" "$1" "$2"
}