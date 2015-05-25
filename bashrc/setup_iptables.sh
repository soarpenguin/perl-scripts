#!/usr/bin/env bash

# allow the network 10.111.11.0/24 and not allow other network connect port 9200
iptables -I INPUT -p tcp --dport 9200 -j DROP
iptables -I INPUT -s 10.111.11.0/24 -p tcp --dport 9200 -j ACCEPT

iptables -I INPUT -p udp --dport 9200 -j DROP
iptables -I INPUT -s 10.111.11.0/24 -p udp --dport 9200 -j ACCEPT

# allow the network 10.111.11.0/24 and not allow other network connect port 9300
iptables -I INPUT -p tcp --dport 9300 -j DROP
iptables -I INPUT -s 10.111.11.0/24 -p tcp --dport 9300 -j ACCEPT

iptables -I INPUT -p udp --dport 9300 -j DROP
iptables -I INPUT -s 10.111.11.0/24 -p udp --dport 9300 -j ACCEPT

service iptables save && /etc/init.d/iptables restart && iptables -L -n
