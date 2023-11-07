#! /usr/bin/env bash

ssid=${1:-Unime的iPhone}

while true; do

networksetup -getairportnetwork en0 | grep -i $ssid 1>/dev/null && echo -e "\x1b[32m已连接\x1b[33m$ssid\x1b[0m" && exit 0

while true; do
  networksetup -getairportpower en0 | grep -i On$ 1>/dev/null && break
  echo -e "\x1b[2m开启WiFi\x1b[0m" && networksetup -setairportpower en0 on && echo -e "\x1b[2mWiFi开启成功，准备连接\x1b[33m$ssid\x1b[0m" && break
done

/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s | grep -i $ssid 1>/dev/null || { echo -e "\x1b[2m未找到热点\x1b[33m$ssid\x1b[0m" && sleep 1 && continue; }

networksetup -setairportnetwork en0 $ssid && echo -e "\x1b[32m成功连接\x1b[33m$ssid\x1b[0m" && exit 0 || { echo -e "\x1b[2m连接失败，重新尝试\x1b[0m" && sleep 1 && continue; }

done
