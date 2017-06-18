#!/bin/bash
# Author: Sean Ewing
# Project: https://github.com/strobilomyces/nordvpn-import-ikev2
# Description: Imports IKEv2-compatible NordVPN servers into Network Manager
#              using the NordVPN API
#
# Usage:
#   sudo bash nordvpn-import-ikev2.sh country_code number_of_vpns
#   e.g. sudo bash nordvpn-import-ikev2.sh dk 7 # 7 VPNs from Denmark
#        sudo bash nordvpn-import-ikev2.sh dk all # All from Denmark
#        sudo bash nordvpn-import-ikev2.sh all all # All servers
#
# Credits:
# Inspired by Milosz Galazka's nordvpn-import script (for tcp/udp)
# https://repository.sleeplessbeastie.eu/milosz/nordvpn-import/

# Configuration
nordvpn_username=""
certificate_file="" # Full path to the NordVPN .pem certificate file


write_config_file () {

  vpn="$1"
  username="$2"
  certificate="$3"

cat << EOF
[connection]
id=${vpn}.ikev2
uuid=$(uuidgen)
type=vpn
autoconnect=false
permissions=user:$SUDO_USER:;
secondaries=

[vpn]
password-flags=1
user=${username}
encap=yes
address=${vpn}
virtual=yes
method=eap
proposal=no
certificate=${certificate}
ipcomp=no
service-type=org.freedesktop.NetworkManager.strongswan

[ipv4]
dns-search=
method=auto

[ipv6]
addr-gen-mode=stable-privacy
dns-search=
ip6-privacy=0
method=auto
EOF

}


usage () {
  printf "\nUsage: $0 two-digit-country-code number-of-vpns\n\n"
  echo "Examples: $0 dk 5 (5 servers from Denmark)"
  echo "          $0 dk all (All servers from Denmark)"
  echo "          $0 all all (All servers from everywhere)"
  printf "\nConsult https://nordvpn.com/servers/ for available countries.\n\n"
}


# Check that user has root access
if [ ! "$USER" == "root" ]; then
  printf "Error: you need root privileges to run this script."
  exit 1
fi

# Check that network-manager-strongswan is present
if ! dpkg-query -s network-manager-strongswan 1>/dev/null 2>&-; then
  printf "Error: you need to install network-manager-strongswan."
  exit 1
fi

# Make sure that username is present.
if [ -z ${nordvpn_username} ]; then
  echo "Error: you need to set your username."
  exit 1
fi

# Make sure the user's certificate file exists.
if ! test -f "$certificate_file"; then
  echo "Error: path to certificate file isn't valid."
  exit 1
fi

# Check that number of parameters is correct.
if [ "$#" -ne 2 ]; then
  printf "\nError: invalid number of parameters.\n"
  usage
  exit 1
fi

# Check that country code parameter has two letters.
# If it does, grab the API and use jq to filter.
if [[ $1 =~ ^[a-z]{,2}$ ]]; then
  country_code="\"${1^^}\""
  vpn_list=$(curl -s 'https://nordvpn.com/api/server' | jq -r '.[] | select('.features.ikev2' == true and .flag == '${country_code}') | .domain')
elif [ "$1" = "all" ]; then
  vpn_list=$(curl -s 'https://nordvpn.com/api/server' | jq -r '.[] | select('.features.ikev2' == true) | .domain')
else
  printf "\nError: '$1' is not a valid country code (e.g. se, dk).\n"
  usage
  exit 1
fi

# Check that the server number parameter is a positive integer.
# If so, grab the first n VPNs.
if [[ "$2" =~ ^[0-9]+$ ]]; then
  vpn_list=$(printf "${vpn_list[@]}" | head -$2)
elif [ "$2" = "all" ]; then
  : # Do nothing (use the whole list of VPNs)
else
  printf "\nError: invalid number of VPNs.\n"
  usage
  exit 1
fi

# Add the VPN config files to Network Manager
for vpn in $vpn_list; do

  output_file="/etc/NetworkManager/system-connections/${vpn}.ikev2"

  # If the file already exists, skip it.
  # If it doesn't, write it and set permissions.
  if ! test -f "$output_file"; then
    write_config_file "$vpn" "$nordvpn_username" "$certificate_file" > "$output_file"
    chmod 600 "$output_file"
    echo "Imported ${vpn} to ${output_file}"
  else
    echo "${vpn} already exists; skipping."
  fi

done

# Refresh Network Manager, so the new VPNs appear
nmcli connection reload
