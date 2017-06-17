# nordvpn-import-ikev2
This bash script grabs a list of IKEv2-compatible servers from NordVPN's API and creates configuration profiles of each for use with Network Manager.

### Requirements
* curl
* jq
* network-manager-strongswan

To install Strongswan, check out NordVPN's [IKEv2/IPsec configuration guide](https://nordvpn.com/tutorials/linux/ikev2ipsec/). You don't need to edit ipsec.conf--just install the required packages, edit constraints.conf, and download the RSA certificate, and this script will take care of the rest.

In the configuration section of this script, put your NordVPN username and the path to the .pem certificate file. You can grab the certificate file with:

`wget https://downloads.nordvpn.com/certificates/root.pem -O ~/NordVPN.pem`

(which will put it in your home directory).

### Usage
* `sudo bash nordvpn-import-ikev2.sh two-digit-country-code number-of-vpns`
* Examples: `sudo bash nordvpn-import-ikev2.sh dk 5` (5 servers from Denmark)
* `sudo bash nordvpn-import-ikev2.sh dk all` (All servers from Denmark)
* `sudo bash nordvpn-import-ikev2.sh all all` (All servers from everywhere)

Take a look at https://nordvpn.com/servers/ for available country codes.

### Troubleshooting
* Make sure you're running the script with bash, and not sh. Otherwise, you'll get strange errors about unexpected operators.
* VPN configuration files are written to Network Manager's connections directory, `/etc/NetworkManager/system-connections/`.

### Notes
I've only tested this with Ubuntu 17.04. Currently (2017-06-17), Ubuntu 16.04/16.10 is having issues with charon-nm that I was unable to resolve even by building Strongswan from source with instructions from the official site. 17.04 fixes these. Other distributions/versions may work, but you'll likely have to tweak a few things.

### Credits:
Inspired by Milosz Galazka's [nordvpn-import script](https://repository.sleeplessbeastie.eu/milosz/nordvpn-import/) for tcp/udp.
