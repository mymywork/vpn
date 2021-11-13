#!/bin/sh

if [ -f /var/run/radattr.$1 ];
then
DOWNSPEED=`/usr/bin/awk '/Actual-Data-Rate-Downstream/ {print $2}' /var/run/radattr.$1`
UPSPEED=`/usr/bin/awk '/Actual-Data-Rate-Upstream/ {print $2}' /var/run/radattr.$1`
IPADDR=`/usr/bin/awk '/Framed-IP-Address/ {print $2}' /var/run/radattr.$1`

##### speed server->client
if [ "${UPSPEED}" != "" ] && [ "${DOWNSPEED}" != "" ]; 
then

ifconfig $1 >> /tmp/lala

tc qdisc del dev $1 root
tc qdisc add dev $1 root handle 1: htb default 2
# upload rate
tc class add dev $1 parent 1: classid 1:1 htb rate ${UPSPEED}Kbit burst 230kb cburst 230kb
# download rate
tc class add dev $1 parent 1: classid 1:2 htb rate ${DOWNSPEED}Kbit burst 230kb cburst 230kb
# filter upload
tc filter add dev $1 protocol ip parent 1: prio 1 u32 match ip src ${IPADDR} flowid 1:1
fi
fi
