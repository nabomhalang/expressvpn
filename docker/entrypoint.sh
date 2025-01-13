#!/bin/bash

# Back up the resolv.conf
cp /etc/resolv.conf /tmp/resolv.conf

# Unmount the resolv.conf and restore it
su -c 'umount /etc/resolv.conf'
cp /tmp/resolv.conf /etc/resolv.conf

# Update init script for expressvpn
sed -i 's/DAEMON_ARGS=.*/DAEMON_ARGS=""/' /etc/init.d/expressvpn

# Restart expressvpn service
service expressvpn restart

# Activate ExpressVPN using expect
/usr/bin/expect /tmp/activateCode.sh

sleep 3

# Set ExpressVPN preferences
expressvpn preferences set auto_connect true
expressvpn preferences set preferred_protocol $PREFERRED_PROTOCOL
expressvpn preferences set lightway_cipher $LIGHTWAY_CIPHER

# Connect to server
if [ -n "$SERVER" ]; then
    expressvpn connect $SERVER
else
    expressvpn connect smart
fi

# Execute passed commands
exec "$@"