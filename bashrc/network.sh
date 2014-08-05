#!/usr/bin/env bash 
  
ETH=$1
ETH=${ETH:-eth0}
IP=`ifconfig $ETH|awk -F '[ :]+' '/inet addr/{print $4}'`
  
while true;
do
    let I+=1
    NOW=`date +"%F %T"`
    TX1=`ifconfig $ETH|grep bytes|awk -F '[ :]+' '{print $9}'`
    RX1=`ifconfig $ETH|grep bytes|awk -F '[ :]+' '{print $4}'`
    sleep 1
    TX2=`ifconfig $ETH|grep bytes|awk -F '[ :]+' '{print $9}'`
    RX2=`ifconfig $ETH|grep bytes|awk -F '[ :]+' '{print $4}'`
    
    let TX=(TX2-TX1)/1024
    let RX=(RX2-RX1)/1024
    let TX_TOTAL+=$TX
    let RX_TOTAL+=$RX
    let TX_AVERAGE=TX_TOTAL/${I}
    let RX_AVERAGE=RX_TOTAL/${I}
    
    clear
    
    printf "%10s\t%20s\n" "Device $ETH [$IP]" "$NOW"
    echo "============================================================="
    printf "%10s\t%20s\t%20s\n" CURRENT: in:${RX}KB/s out:${TX}KB/s
    printf "%10s\t%20s\t%20s\n" AVERAGE: in:${RX_AVERAGE}KB/s out:${TX_AVERAGE}KB/s
    printf "%10s\t%20s\t%20s\n" TOTAL: in:${RX_TOTAL}KB out:${TX_TOTAL}KB
done

