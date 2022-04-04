#!/bin/sh
iptables -t nat -D POSTROUTING -s 10.8.2.0/24 -o tunG0 -j MASQUERADE
ip route del 0.0.0.0/1 via 10.10.10.2 dev tunG0
ip route del 128.0.0.0/1 via 10.10.10.2 dev tunG0


#2、添加国内路由
ip rule del from all lookup 10 pri 10
ip rule add from all lookup 10 pri 10
/root/chnroutes/vpn-up.sh

#3、添加特殊目的走国内路由
ip rule del from all lookup 15 pri 15
ip rule add from all lookup 15 pri 15
/root/dst_noVPN_route.sh


OLDGW=$(ip route show 0/0 | sed -e 's/^default//')
ip route add 13.250.62.24 $OLDGW table 15
ip route add 13.228.30.146 $OLDGW table 15

#
#nat
iptables -t nat -A POSTROUTING -s 10.8.2.0/24 -o tunG0 -j MASQUERADE
#默认路由指向GRE
ip route add 0.0.0.0/1 via 10.10.10.2 dev tunG0
ip route add 128.0.0.0/1 via 10.10.10.2 dev tunG0
