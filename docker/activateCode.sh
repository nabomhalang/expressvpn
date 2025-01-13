#!/usr/bin/expect
exp_internal 1
set timeout 20

spawn expressvpn activate
expect {
  "code:" {
      send "$env(ACTIVATION_CODE)\r"
      expect "information."
      send "n\r"
    }
}
expect eof