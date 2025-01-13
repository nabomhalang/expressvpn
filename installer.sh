#!/bin/bash

source "$(pwd)/sh/index.sh"

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

# Display title
echo -e "${bold}${purple}ExpressVPN Docker Build Script${nc}\n"

# Introduction message
echo -e "${blue}${bold}Building ExpressVPN Docker Containers${nc}\n"

set +e

# Generate and display build ID
start_spinner "${yellow}${bold}> Generating Build ID...${nc}"
sleep 1
build="$(printf '%x' $(date +%s))"
stop_spinner $?
[[ $? -eq 0 ]] && echo -e "${green}[+] Build ID: ${build}${nc}"

# Define and display Docker tag
start_spinner "${yellow}${bold}> Generating Docker container tag...${nc}"
sleep 1
tag="3.80.0.${build}"
stop_spinner $?
[[ $? -eq 0 ]] && echo -e "${green}[+] Docker container tag: ${tag}${nc}"

# Validation and input for ExpressVPN activation code
start_spinner "${yellow}${bold}> Validating ExpressVPN activation code...${nc}"
sleep 1
if [[ -z "$ACTIVATION_CODE" ]]; then
  stop_spinner -1
  prompt_hidden_input "${cyan}>> Enter your ExpressVPN ACTIVATION CODE: ${nc}" ACTIVATION_CODE

  if [[ -z "$ACTIVATION_CODE" ]]; then
      echo -e "${red}[-] No ACTIVATION_CODE provided. Exiting.${nc}"
      exit 1
  else
      echo -e "${green}[+] ExpressVPN ACTIVATION CODE captured successfully.${nc}"
      export ACTIVATION_CODE=$ACTIVATION_CODE
  fi
else
  stop_spinner 0
  echo -e "${green}[+] ExpressVPN ACTIVATION CODE captured successfully.${nc}"
fi

# Create Dockerfile
start_spinner "${yellow}${bold}> Creating Dockerfile...${nc}"
sleep 1
cat > Dockerfile << 'EOF'
FROM debian:bookworm-slim AS expressvpn-base

LABEL maintainer="op@nabomhalang.co.kr"

# Set environment variables
ENV VPN_ACTIVE_CODE=Code
ENV LOCATION=smart
ENV PREFERRED_PROTOCOL=auto
ENV LIGHTWAY_CIPHER=auto

ARG APP=expressvpn_3.81.0.2-1_amd64.deb

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libterm-readkey-perl ca-certificates wget expect iproute2 iputils-ping curl procps libnm0 iptables && \
    wget -q "https://www.expressvpn.works/clients/linux/${APP}" -O /tmp/${APP} && \
    dpkg -i /tmp/${APP} && \
    rm -rf /var/lib/apt/lists/* /tmp/*.deb && \
    apt-get purge -y --auto-remove wget

COPY ./docker/entrypoint.sh /tmp/entrypoint.sh
COPY ./docker/activateCode.sh /tmp/activateCode.sh

ENTRYPOINT ["/bin/bash", "/tmp/entrypoint.sh"]

FROM expressvpn-base AS expressvpn-wo-iptables

RUN apt-get remove -y iptables
EOF
stop_spinner $?
[[ $? -eq 0 ]] && echo -e "${green}[+] Dockerfile created successfully.${nc}"

# Build Docker image
start_spinner "${yellow}${bold}> Building Docker image...${nc}"
docker build --pull --no-cache --rm --force-rm -f Dockerfile -t expressvpn:${tag} . 
if [[ $? -eq 0 ]]; then
  stop_spinner 0
  echo -e "${green}[+] Successfully created ExpressVPN Docker image.${nc}"
else
  stop_spinner 1
  echo -e "${bold}${red}[-] Error occurred during Docker image build.${nc}"
  exit 1
fi

# Remove existing test container if any
start_spinner "${yellow}${bold}> Remove test container if it is already running...${nc}"
if docker ps -a | grep -q expressvpn-na; then
  docker stop expressvpn-na && docker rm expressvpn-na > /dev/null
fi
stop_spinner $?

# Run Testing expressvpn container
start_spinner "${yellow}${bold}> Run testing expressVPN container...${nc}"
docker run \
    --env=ACTIVATION_CODE=${ACTIVATION_CODE} \
    --cap-add=NET_ADMIN \
    --device=/dev/net/tun \
    --privileged \
    --detach=true \
    --tty=true \
    --name=expressvpn-na \
    expressvpn:${tag} \
    /bin/bash > /dev/null
run_status=$?
stop_spinner $run_status
if [[ $run_status -eq 0 ]]; then
  echo -e "${green}[+] Successfully ran the expressVPN container.${nc}"
else
  echo -e "${bold}${red}[-] Error occurred while running expressVPN container.${nc}"
  exit 1
fi 

# Wait for 20 seconds to give the container time to initialize
start_spinner "${yellow}${bold}> Waiting 20 seconds for the container to initialize...${nc}"
sleep 20
stop_spinner 0

# Execute the command to check the status of the expressVPN
start_spinner "${yellow}${bold}> Checking the status of the expressVPN...${nc}"
status="$(docker exec -i expressvpn-na expressvpn status)"
check_status=$?
stop_spinner $check_status
if [[ $check_status -eq 0 ]]; then
  echo -e "${green}[+] expressVPN status fetched successfully ${nc}"
  echo "$status"
else
  echo -e "${bold}${red}[-] Failed to fetch expressVPN status.${nc}"
  exit 1
fi

start_spinner "${yellow}${bold}> Please select the country to which you want to connect your VPN. ${NC}"
sleep 1
stop_spinner $?