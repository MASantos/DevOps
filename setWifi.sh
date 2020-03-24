#!/bin/bash

setup_common(){
ip link set wlp3s0 up
systemctl enable NetworkManager.service
systemctl enable wpa_supplicant.service
systemctl start wpa_supplicant.service
}

setup_wpa(){
setup_common
[ $? -gt 0 ] && exit 1
wpa_supplicant -B -i wlp3s0 -c <(wpa_passphrase DragonFaculty '_PASSWORDHERE_' )
[ $? -gt 0 ] && exit 1
dhcpcd wlp3s0
[ $? -gt 0 ] && exit 1
}

setup_nm(){
setup_common
systemctl start NetworkManager.service
nmcli r wifi on
#nmcli -a -s dev wifi connect DragonFaculty
}

setdown(){
nmcli r wifi off
systemctl stop NetworkManager.service
systemctl stop  wpa_supplicant.service
systemctl disable wpa_supplicant.service
systemctl disable NetworkManager.service
#no need for this as first cmd brings it down already
#ip link set wlp3s0 down
}

case $1 in
	-h|--help|--help) echo "$0 [down] " ; exit ;;
	down) setdown ; exit ;;
	*) setup_nm ; exit ;;
esac


