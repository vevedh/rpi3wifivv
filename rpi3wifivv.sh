#!/bin/sh

#Check for Root
ifaces=/etc/network/interfaces
cp $ifaces /etc/network/interfaces.bak
LUID=$(id -u)
if [ $LUID -ne 0 ]; then
	echo "$0 dois etre executer en root"
	exit 1
fi

cat > /etc/dnsmasq.conf <<EOF
interface=wlan0
listen-address=10.0.0.1
bind-interfaces
domain-needed
server=8.8.8.8
dhcp-range=10.0.0.20,10.0.0.150,255.255.255.0,12h
EOF

if [ `cat /etc/dhcpcd.conf|grep -c "^denyinterfaces"` -eq 0 ]; then
echo "denyinterfaces wlan0" >> /etc/dhcpcd.conf
fi

echo 1 > /proc/sys/net/ipv4/ip_forward

cat hostapd.conf.veve > /etc/hostapd/hostapd.conf

cat iptables.ipv4.nat.veve > /etc/iptables.ipv4.nat

sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf

if [ `cat /etc/rc.local|grep -c "^ifconfig"` -eq 0 ];  then

sed -i -- 's/exit 0/ /g' /etc/rc.local
cat >> /etc/rc.local <<EOF
ifconfig wlan0 down
ifconfig wlan0 10.0.0.1 netmask 255.255.255.0 up
service dnsmasq restart
iptables-restore < /etc/iptables.ipv4.nat
exit 0
EOF

fi
