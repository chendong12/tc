#!/usr/bin/bash
# 以下脚本文件用在服务器端，对于OPENVPN客户端的下载流量进行限速（即服务器端出流量），带宽单位为kbits/s
#定义链路带宽
LinkCeilDownSpeed=30000            #链路最大下载带宽
LinkCeilUploadSpeed=30000          #链路最大上传带宽
LinkRateDownSpeed=29000           #链路保障下载带宽
LinkRateUploadSpeed=29000         #链路保障上传带宽

#定义VPN 用户的最大带宽和保障带宽
UserCeilDownSpeed=29000         #特殊用户最大下载带宽
UserCeilUploadSpeed=29000       #特殊用户最大上传带宽
UserRateDownSpeed=29000        #特殊用户保障下载带宽
UserRateUploadSpeed=29000      #特殊用户保障上传带宽

#定义其他用户的最大带宽合保障带宽
OtherCeilDownSpeed=29000             #其他用户最大下载带宽
OtherCeilUploadSpeed=29000           #其他用户最大上传带宽
OtherRateDownSpeed=29000            #其他用户保障下载带宽
OtherRateUploadSpeed=29000          #其他用户保障上传带宽

###################定义限速网卡######################################
NetDevice=tun100
#定义VPN客户端地址前缀
vpn_address_pre=10.8.1
#####################################################################
#定义用户
. /root/all_users.sh

#计算出数组中最后一个index
let vpn_total_number=${#vpnSpeed[@]}*2+4
#echo $vpn_total_number

# 清除接口上的队列及 mangle 表
/usr/sbin/tc qdisc del dev $NetDevice root    2> /dev/null > /dev/null

#以下是上传限速
/usr/sbin/tc qdisc add dev $NetDevice root handle 1: htb default 255
##################################定义 class##########################################################################
/usr/sbin/tc class add dev $NetDevice parent 1: classid 1:1 htb rate ${LinkRateUploadSpeed}kbit ceil ${LinkCeilUploadSpeed}kbit
#
for((i = 6; i <= $vpn_total_number; i+=2))
do
   /usr/sbin/tc class add dev $NetDevice parent 1:1 classid 1:$i htb rate ${vpnSpeed[$i]}kbit ceil ${vpnSpeed[$i]}kbit
   /usr/sbin/tc class add dev $NetDevice parent 1:1 classid 1:$(($i+1)) htb rate ${vpnSpeed[$i]}kbit ceil ${vpnSpeed[$i]}kbit
done
#
/usr/sbin/tc class add dev $NetDevice parent 1:1 classid 1:255 htb rate ${OtherRateUploadSpeed}kbit ceil ${OtherCeilUploadSpeed}kbit
#####################################################################################################################
##############################. 定义匹配VPN客户端地址. #################################################################
for((i = 6; i <= $vpn_total_number; i+=2))
do
        /usr/sbin/tc filter add dev $NetDevice protocol ip parent 1:0 prio 1 u32 match ip dst $vpn_address_pre.$i flowid 1:$i
        /usr/sbin/tc filter add dev $NetDevice protocol ip parent 1:0 prio 1 u32 match ip dst $vpn_address_pre.$(($i+1)) flowid 1:$(($i+1))
done
####################################################################################################################
##############################.  定义队列.  ############################################################################
for((i = 6; i <= $vpn_total_number; i+=2))
do
   /usr/sbin/tc qdisc add dev $NetDevice parent 1:$i handle $i: sfq perturb 10
   /usr/sbin/tc qdisc add dev $NetDevice parent 1:$(($i+1)) handle $(($i+1)): sfq perturb 10
done
/usr/sbin/tc qdisc add dev $NetDevice parent 1:255 handle 255: sfq perturb 10
echo "`date` 成功执行了限速策略"
