#!/bin/bash

source "$(pwd)/sh/color.sh"
source "$(pwd)/sh/spinner.sh"
source "$(pwd)/sh/utils.sh"

echo -e "${bold}${purple}                                 ___.                  .__           .__                               ${nc}"
echo -e "${bold}${purple}                      ____ _____ \\_ |__   ____   _____ |  |__ _____  |  | _____    ____    ____        ${nc}"
echo -e "${bold}${purple}                     /    \\\\__  \\ | __ \\ /  _ \\ /     \\|  |  \\\\__  \\ |  | \\__  \\  /    \\  / ___\\       ${nc}"
echo -e "${bold}${purple}                    |   |  \\/ __ \\| \\_\\ (  <_> )  Y Y  \\   Y  \\/ __ \\|  |__/ __ \\|   |  \\/ /_/  >      ${nc}"
echo -e "${bold}${purple}                    |___|  (____  /___  /\\____/|__|_|  /___|  (____  /____(____  /___|  /\\___  /       ${nc}"
echo -e "${bold}${purple}                         \\/     \\/    \\/             \\/     \\/     \\/          \\/     \\//_____/        ${nc}"
echo -e "${bold}${purple}                                                  ____   _____________________                         ${nc}"
echo -e "${bold}${purple}  ____ ___  ________________   ____   ______ _____\\   \\ /   /\\______   \\      \\                        ${nc}"
echo -e "${bold}${purple}_/ __ \\\\  \\/  /\\____ \\_  __ \\_/ __ \\ /  ___//  ___/\\   Y   /  |     ___/   |   \\                       ${nc}"
echo -e "${bold}${purple}\\  ___/ >    < |  |_> >  | \\/\\  ___/ \\___ \\ \\___ \\  \\     /   |    |  /    |    \\                      ${nc}"
echo -e "${bold}${purple} \\___  >__/\\_ \\|   __/|__|    \\___  >____  >____  >  \\___/    |____|  \\____|__  /                      ${nc}"
echo -e "${bold}${purple}     \\/      \\/|__|               \\/     \\/     \\/                            \\/                       ${nc}"
echo -e "${bold}${purple}                                               .__                 __         .__  .__                 ${nc}"
echo -e "${bold}${purple}                                               |__| ____   _______/  |______  |  | |  |   ___________  ${nc}"
echo -e "${bold}${purple}                                               |  |/    \\ /  ___/\\   __\\__  \\ |  | |  | _/ __ \\_  __ \\ ${nc}"
echo -e "${bold}${purple}                                               |  |   |  \\___ \\  |  |  / __ \\|  |_|  |_\\  ___/|  | \\/ ${nc}"
echo -e "${bold}${purple}                                               |__|___|  /____  > |__| (____  /____/____/\\___  >__|    ${nc}"
echo -e "${bold}${purple}                                                       \\/     \\/            \\/               \\/        ${nc}"
echo
echo

echo -e "${blue}${bold}Build Scripts expressvpn containers${nc}"
echo

start_spinner "${yellow}${bold}> Get Build id${nc}"
sleep 1
build="$(printf '%x' `date +%s`)"
stop_spinner $?
if [ $? -eq 0 ]; then
  echo -e "${green}[+] build id : ${build}${nc}"
fi

start_spinner "${yellow}${bold}> Get the docker container tag...${nc}"
sleep 1
tag="3.80.0.${build}"
stop_spinner $?
if [ $? -eq 0 ]; then
  echo -e "${green}[+] Docker container tag : ${tag}${nc}"
fi


start_spinner "${yellow}${bold}> Check expessVPN activation code...${nc}"
sleep 1
if [ -z "$ACTIVATION_CODE" ]; then
    stop_spinner -1
    echo -e "${bold}${red}[-] expressVPN ACTIVATION_CODE environment is not set!${nc}"
    echo -en "${cyan}>> Please enter your expressVPN ACTIVATION CODE: ${nc}"

    activation_code=""
    while IFS= read -r -s -n1 char; do
        if [[ $char == $'\0' ]] || [[ $char == $'\n' ]]; then
            break
        fi
        if [[ $char == $'\177' ]]; then
            if [[ -n $activation_code ]]; then
                activation_code=${activation_code%?}
                printf '\b \b'
            fi
        else
            activation_code+="$char"
            printf '*'
        fi
    done
    echo  

    if [ -z "$activation_code" ]; then
        echo -e "${bold}${red}[-] No ACTIVATION_CODE provided. Exiting.${nc}"
        exit 1
    else
        echo -e "${bold}${green}[+] expressVPN ACTIVATION CODE captured successfully.${nc}"
    fi

    export ACTIVATION_CODE="$activation_code"
else
    stop_spinner 0
    echo -e "${bold}${green}[+] expressVPN ACTIVATION CODE captured successfully.${nc}"
fi

start_spinner "${yellow}${bold}> Creating Dockerfile with information...${nc}"
sleep 1
cat > Dockerfile <<EOF
FROM debian:bookworm-slim AS expressvpn-base

LABEL maintainer="op@nabomhalang.co.kr"

# Set environment variables
ENV VPN_ACTIVE_CODE=$ACTIVATION_CODE
ENV LOCATION=smart
ENV PREFERRED_PROTOCOL=auto
ENV LIGHTWAY_CIPHER=auto

ARG APP=expressvpn_3.81.0.2-1_amd64.deb  # Ensure the architecture matches the base image

RUN apt-get update && apt-get install -y --no-install-recommends \
    libterm-readkey-perl ca-certificates wget expect iproute2 iputils-ping curl procps libnm0 iptables \
    && rm -rf /var/lib/apt/lists/* \
    && wget -q "https://www.expressvpn.works/clients/linux/${APP}" -O /tmp/${APP} \
    && dpkg -i /tmp/${APP} \
    && rm -rf /tmp/*.deb \
    && apt-get purge -y --auto-remove wget

COPY entrypoint.sh /tmp/entrypoint.sh
COPY codeActivation.sh /tmp/codeActivation.sh

ENTRYPOINT ["/bin/bash", "/tmp/entrypoint.sh"]

FROM expressvpn-base AS expressvpn-wo-iptables

RUN apt-get remove -y iptables
EOF
stop_spinner $?

if [ $? -eq 0 ]; then
  echo -e "${bold}${green}[+] Dockerfile created successfully with the provided ACTIVATION_CODE.${nc}"
fi


start_spinner "${yellow}${bold}> Build the docker image...${nc}"
sleep 1
docker build --pull --no-cache --rm --force-rm -f Dockerfile -t expressvpn:${tag} .
if [ $? -eq 0 ]; then
  stop_spinner $?
  echo -e "${bold}${green}[+] Create expressvpn image successfully.${nc}"
else
  stop_spinner $?
  echo -e "${bold}${red}[-] An error occurred during docker image build.${nc}"
  exit 1
fi
