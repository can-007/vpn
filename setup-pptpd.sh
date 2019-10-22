#!/bin/bash

#==========================================================
#==========================================================
username='vpn'
password='vpn'
#==========================================================
#==========================================================

echo '[INFO] update repository'
apt-get update

echo '[INFO] install pptpd'
echo 'y' | apt-get install pptpd

echo '[INFO] configure IPs'
local_ip=`ifconfig | awk -F': ' 'NF>1{ nin=$1;}NF==1{ print $1; exit }' | awk -F' ' '{ if($1=="inet") print $2 }'`
remote_ip=`echo $local_ip | awk -F'.' '{ print $1 "." $2 "." $3 "." ($4)+1 "-255" }'`
sed -i "0,/.*localip .*\..*\..*\..*/s//SETLOCALIP/" /etc/pptpd.conf
sed -i "0,/.*remoteip .*\..*\..*\..*/s//SETREMOTEIP/" /etc/pptpd.conf
sed -i "s/SETLOCALIP/localip $local_ip/" /etc/pptpd.conf
sed -i "s/SETREMOTEIP/remoteip $remote_ip/" /etc/pptpd.conf

echo '[INFO] configure credentials'
echo -e "$username\tpptpd\t$password\t*" >> /etc/ppp/chap-secrets

echo '[INFO] configure DNS'
dns1=`cat /etc/resolv.conf | awk -F'nameserver ' 'NF==2{ print $2; exit }'`
dns2='8.8.4.4'
sed -i '0,/.*dns .*\..*\..*\..*/s//firstDNS/' /etc/ppp/pptpd-options
sed -i '0,/.*dns .*\..*\..*\..*/s//secondDNS/' /etc/ppp/pptpd-options
sed -i "s/firstDNS/ms-dns $dns1/" /etc/ppp/pptpd-options
sed -i "s/secondDNS/ms-dns $dns2/" /etc/ppp/pptpd-options

echo '[INFO] configure network, MTU and iptables'
net_interface_name=`ifconfig | awk -F': ' 'NF>1{ print $1; exit}'`
sysctl net.ipv4.ip_forward=1
ifconfig $net_interface_name mtu 1600 up
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -t nat -A POSTROUTING -o $net_interface_name -j MASQUERADE

echo '[INFO] ======================================================================================='
echo '[INFO] CRITICAL INFORMATION:'
echo '[INFO] ====================='
echo "[INFO] network interface name: $net_interface_name"
echo "[INFO] local  IP: $local_ip"
echo "[INFO] remote IP: $remote_ip"
echo "[INFO] DNS1: $dns1"
echo "[INFO] DNS2: $dns2"
echo "[INFO]"
echo "[INFO]"
echo "[INFO]"
echo "[INFO] SYSTEM STATUS:"
echo '[INFO] =============='
echo "[INFO] iptable rules in all chains:"
iptables --list
echo "[INFO] iptable rules default table:"
iptables --list-rules
echo "[INFO] iptable rules nat     table:"
iptables --list-rules -t nat
echo '[INFO] ======================================================================================='

echo '[INFO] restart pptpd'
service pptpd restart