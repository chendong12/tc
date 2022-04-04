#!/bin/bash
#特殊地址不走 GRE
####################################################################
OLDGW=$(ip route show 0/0 | sed -e 's/^default//')
ip route add 149.129.0.0/16 $OLDGW table 15
ip route add 8.219.1.0/24 $OLDGW table 15
