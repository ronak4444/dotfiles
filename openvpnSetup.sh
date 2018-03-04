#!/bin/bash

# SCRIPT NOT TESTED

#################################
# The script performs following task
# - disable ipv6
# - install openvpn
# - fetch pia config files
# - create vpn.sh startup script
# - redirect all traffic to via vpn
# - TODO  set openvpn.service Service parameter
# - TODO  create .secrets file
#################################

# variables
VPNLOCATION=Singapore
OPENVPN_HOME=/etc/openvpn

# Disable ipv6
# Because vpn service have ipv6
sudo /bin/su -c "echo 'net.ipv6.conf.default.disable_ipv6=1' >> /etc/sysctl.conf"
sudo /bin/su -c "echo 'net.ipv6.conf.all.disable_ipv6=1' >> /etc/sysctl.conf"

# install openvpn
sudo apt install openvpn

# fetch pia configs
cd /etc/openvpn
sudo wget https://www.privateinternetaccess.com/openvpn/openvpn.zip
sudo apt install unzip
sudo unzip openvpn.zip

# create openvpn startup script
cat << 'EOF' >> ~/vpn.sh
#!/bin/sh

exec 1>/var/log/vpn 2>&1

case "$1" in
  start)
    echo "Adding .secrets to ovpn config file"
    sudo sed -i 's/auth-users-pass.*/auth-users-pass .secrets/g' $OPENVPN_HOME/$VPNLOCATION.ovpn
    echo "Connecting to PIA VPN "
    /usr/sbin/openvpn --config /etc/openvpn/$VPNLOCATION.ovpn &
    ;;
  stop)
    echo "Closing connection to PIA VPN "
    killall openvpn
    ;;
  *)
    echo "Usage: /etc/openvpn/vpn.sh {start|stop}"
    exit 1
    ;;
esac
exit 0
EOF

sudo mv ~/vpn.sh $OPEVPN_HOME/
sudo chmod 777 $OPENVPN_HOME/openvpn-pia.sh

# route all traffic via vpn
sudo /bin/su -e "echo 'redirect-gateway def1' >> ${OPENVPN_HOME}/${VPNLOCATION}.ovpn"

# TODO 
# create /etc/openvpn/.secrets file with username and password in 2 lines and make it private for security

# TODO Systemd settings
# set below parameter in /etc/systemd/system/multi-user.target.wants/openvpn.service  [Service] parameter
# ExecStart=/bin/bash /etc/openvpn/vpn.sh start

