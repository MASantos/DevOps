#!/bin/bash
# Pedestrian Port Knocking setup for IPTABLES
# (c) Miguel A. Santos 2007. GPL
# Heavily (99.9%) based on iptables setup provided by
# (c) neepOnline 2006, http://wwww.neep.co.uk
#
# It sets up a Port Knocking rule based on iptables
# for accessing port 'sp'.
#
# Magic melody for opening port is a sequence of tcp
# packets addressed to ports 'p1', 'p2' and 'p3', in
# this order, with tcp state NEW and all three notes
# must be played within 'tot' seconds since first packet.
#
# Adapted for implementing Port Knocking on different iptables
# and chains, and for ease deploy and reset.
#
############################################################
#

i=/usr/sbin/iptables ## IPTables binary
sp=22222 ## port to secure

#Magic melody:
p1=80 ## port to touch first : http
p2=21 ## port to touch second : ftp
p3=990 ## port to touch third : ftps
tot=10 ## time out in seconds

#
#Current ssh port 
SSHp=206  ## sshd is listening to this port, where users log in, and which we are hiding from direct access.
#############

TABLE="-t nat"
CHAIN="INPUT"

EDCHN="-A SESAM"

#Recomended reference
# iptables -R INPUT 1 -j SESAM -i eth0 -p tcp -m state --state ! ESTABLISHED
# iptables -t nat -I PREROUTING -j SESAM -i eth0 -p tcp -m multiport --dports 22222,80,21,990 -m state --state ! ESTABLISHED

ipt_knock(){
$i $TABLE -N SESAM

$i $TABLE -N kc
$i $TABLE -N kc1
$i $TABLE -N kc2

$i $TABLE $EDCHN  -m state --state NEW -p tcp --dport $sp -m recent --rcheck --name portKnock --seconds $tot -j kc
$i $TABLE $EDCHN  -m state --state NEW -p tcp --dport $p1 -m recent --name portKnock2 --set -j DROP
$i $TABLE $EDCHN  -m state --state NEW -p tcp --dport $p2 -m recent --rcheck --name portKnock2 --seconds $tot -j kc1
$i $TABLE $EDCHN  -m state --state NEW -p tcp --dport $p3 -m recent --rcheck --name portKnock1 --seconds $tot -j kc2

$i $TABLE -A kc -m recent --name portKnock --update -j LOG --log-prefix "SFW2-SESAMKNOCK-ACC-TCP "
#$i $TABLE -A kc -m recent --name portKnock --remove -j ACCEPT
$i $TABLE -A kc -m recent --name portKnock --remove -p tcp -j DNAT --to-destination :$SSHp

$i $TABLE -A kc1 -m recent --name portKnock2 --remove
$i $TABLE -A kc1 -m recent --name portKnock1 --set -j DROP

$i $TABLE -A kc2 -m recent --name portKnock1 --remove
$i $TABLE -A kc2 -m recent --name portKnock --set -j DROP

$i $TABLE $EDCHN  -m state --state NEW -m tcp -p tcp --dport $[p1 - 1] -m recent --name portKnock2 --remove -j DROP
$i $TABLE $EDCHN  -m state --state NEW -m tcp -p tcp --dport $[p1 + 1] -m recent --name portKnock2 --remove -j DROP
$i $TABLE $EDCHN  -m state --state NEW -m tcp -p tcp --dport $[p2 - 1] -m recent --name portKnock1 --remove -j DROP
$i $TABLE $EDCHN  -m state --state NEW -m tcp -p tcp --dport $[p2 + 1] -m recent --name portKnock1 --remove -j DROP
$i $TABLE $EDCHN  -m state --state NEW -m tcp -p tcp --dport $[p3 - 1] -m recent --name portKnock --remove -j DROP
$i $TABLE $EDCHN  -m state --state NEW -m tcp -p tcp --dport $[p3 + 1] -m recent --name portKnock --remove -j DROP
$i $TABLE $EDCHN  -j DROP

}

reset(){
chain="SESAM"
echo "Deleting rules for chain $chain"
for r in `awk 'BEGIN{for(i=0;i<11;i++)print i}'` ; do iptables $TABLE -D $chain 1 ;done
echo "Deleting chain $chain"
iptables $TABLE -X $chain
echo "Check reference to chain $chain in table $TABLE"

for c in " " 1 2 ; do chain="kc${c}" ; echo "Deleting rules for chain $chain" ; for r in `awk 'BEGIN{for(i=0;i<2;i++)print i}'` ; do iptables $TABLE -D $chain 1 ;done; echo "Deleting chain $chain" ; iptables $TABLE -X $chain ; done
}

ipt_bkp(){
echo "Backing up iptables"
[ -s /etc/iptables ] && cp /etc/iptables /etc/iptables.bkp
iptables-save > /etc/iptables

localbkp="iptables_`date -Idate`_personal.bkp"
echo "Backing up local iptables: $localbkp"
[ -s ~/FIREWALL/$localbkp ] && cp ~/FIREWALL/$localbkp ~/FIREWALL/${localbkp}.bkp
iptables-save > $localbkp
}


[ $# -gt 0 ] && test "$1" == "-r" && reset && ipt_bkp && exit

[ $# -eq 0 ] && ipt_knock && ipt_bkp && exit

echo "Nothing done..."
