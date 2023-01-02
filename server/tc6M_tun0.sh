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
NetDevice=tun0
#定义VPN客户端地址前缀
vpn_address_pre=10.8.0
#####################################################################
#定义用户
vpnSpeed[6]=29000;vpnUser[6]=home
vpnSpeed[8]=29000;vpnUser[8]=hunan
vpnSpeed[10]=29000;vpnUser[10]=bj
vpnSpeed[12]=29000;vpnUser[12]=huabei
vpnSpeed[14]=29000;vpnUser[14]=hangzhou
vpnSpeed[16]=29000;vpnUser[16]=shanxi
vpnSpeed[18]=29000;vpnUser[18]=bh_tiyu
vpnSpeed[20]=29000;vpnUser[20]=macos
vpnSpeed[22]=29000;vpnUser[22]=86_tun0
vpnSpeed[24]=29000;vpnUser[24]=85_tun0
vpnSpeed[26]=29000;vpnUser[26]=85_tun0_hk
vpnSpeed[28]=29000;vpnUser[28]=85_tun1
vpnSpeed[30]=12480;vpnUser[30]=xhl505
vpnSpeed[32]=12480;vpnUser[32]=xhl506
vpnSpeed[34]=6144;vpnUser[34]=xhl_shandong
vpnSpeed[36]=4096;vpnUser[36]=xhl_hangzhou
vpnSpeed[38]=4096;vpnUser[38]=xhl_shenzheng
vpnSpeed[40]=4096;vpnUser[40]=xhl_yiwu
vpnSpeed[42]=10240;vpnUser[42]=sd_xinhai
vpnSpeed[44]=10240;vpnUser[44]=sd_tky
vpnSpeed[46]=3072;vpnUser[46]=bj_epc
vpnSpeed[48]=3072;vpnUser[48]=tj_yuantai
vpnSpeed[50]=3072;vpnUser[50]=sd_tiandi
vpnSpeed[52]=3072;vpnUser[52]=hz_shibd1
vpnSpeed[54]=3072;vpnUser[54]=hz_shibd2
vpnSpeed[56]=3072;vpnUser[56]=hz_jianbo1
vpnSpeed[58]=3072;vpnUser[58]=hz_jianbo2
vpnSpeed[60]=4096;vpnUser[60]=xm_wlf
vpnSpeed[62]=3072;vpnUser[62]=bj_ganjin
vpnSpeed[64]=3072;vpnUser[64]=bj_ganjin2
vpnSpeed[66]=3072;vpnUser[66]=sc_liao




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
