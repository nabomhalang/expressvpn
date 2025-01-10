#!/bin/bash

# 색상 설정 (ANSI escape codes)
export bold="\033[1m"
export dim="\033[2m"
export underlined="\033[4m"
export blink="\033[5m"
export reverse="\033[7m"
export hidden="\033[8m"

export black="\033[30m"
export red="\033[31m"
export green="\033[32m"
export yellow="\033[33m"
export blue="\033[34m"
export purple="\033[35m"
export cyan="\033[36m"
export white="\033[37m"

export bg_black="\033[40m"
export bg_red="\033[41m"
export bg_green="\033[42m"
export bg_yellow="\033[43m"
export bg_blue="\033[44m"
export bg_magenta="\033[45m"
export bg_cyan="\033[46m"
export bg_white="\033[47m"

export nc="\033[0m" # no color

# 심볼 사용에 대한 스타일 설정
export on_success="${bold}${green}✔${nc}"
export on_fail="${bold}${red}✖${nc}"
