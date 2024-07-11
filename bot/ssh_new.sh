#!/bin/bash

clear
domen=$(cat /etc/xray/domain)
portsshws=$(grep -w "SSH Websocket" ~/log-install.txt | cut -d: -f2 | awk '{print $1}')
wsssl=$(grep -w "SSH SSL Websocket" /root/log-install.txt | cut -d: -f2 | awk '{print $1}')

echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " ${COLBG1}            • SSH PANEL MENU •          ${NC} "
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# Mengambil data dari file data.txt
Login=$(sed -n '1p' data.txt)
Pass=$(sed -n '2p' data.txt)
masaaktif=$(sed -n '3p' data.txt)

CEKFILE=/etc/xray/ssh.txt
if [ ! -f "$CEKFILE" ]; then
  touch /etc/xray/ssh.txt
fi

if grep -qw "$Login" /etc/xray/ssh.txt; then
  echo -e "  [Error] Username \e[31m$Login\e[0m already exists"
  echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo ""
  read -n 1 -s -r -p "  Press any key to back on menu"
  menu-ssh
fi

if [ -z "$Login" ]; then
  echo -e " [Error] Username cannot be empty "
  echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo ""
  read -n 1 -s -r -p "    Press any key to back on menu"
  menu-ssh
fi

echo "$Login" >> /etc/xray/ssh.txt

if [ -z "$Pass" ]; then
  echo -e "  [Error] Password cannot be empty "
  echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo ""
  read -n 1 -s -r -p "   Press any key to back on menu"
  menu-ssh
fi

if [ -z "$masaaktif" ]; then
  echo -e "  [Error] EXP Date cannot be empty "
  echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo ""
  read -n 1 -s -r -p "  Press any key to back on menu"
  menu-ssh
fi

clear
IP=$(curl -sS ifconfig.me)
ossl=$(grep -w "OpenVPN" /root/log-install.txt | cut -f2 -d: | awk '{print $6}')
opensh=$(grep -w "OpenSSH" /root/log-install.txt | cut -f2 -d: | awk '{print $1}')
db=$(grep -w "Dropbear" /root/log-install.txt | cut -f2 -d: | awk '{print $1,$2}')
ssl=$(grep -w "Stunnel4" ~/log-install.txt | cut -d: -f2)
sqd=$(grep -w "Squid" ~/log-install.txt | cut -d: -f2)
ovpn=$(netstat -nlpt | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)
ovpn2=$(netstat -nlpu | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)
OhpSSH=$(grep -w "OHP SSH" /root/log-install.txt | cut -d: -f2 | awk '{print $1}')
OhpDB=$(grep -w "OHP DBear" /root/log-install.txt | cut -d: -f2 | awk '{print $1}')
OhpOVPN=$(grep -w "OHP OpenVPN" /root/log-install.txt | cut -d: -f2 | awk '{print $1}')

sleep 1
clear
useradd -e $(date -d "$masaaktif days" +"%Y-%m-%d") -s /bin/false -M $Login
exp=$(chage -l $Login | grep "Account expires" | awk -F": " '{print $2}')
echo -e "$Pass\n$Pass\n" | passwd $Login &> /dev/null

output=$(cat <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ${COLBG1}      • SSH ACCOUNT INFORMATION •       ${NC} 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Username   : $Login
  Password   : $Pass
  Expired On : $exp
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  IP         : $IP
  Host       : $domen
  OpenSSH    : $opensh
  Dropbear   : $db
  SSH-WS     : $portsshws, 8880
  SSH-SSL-WS : $wsssl
  SSH-UDP    : 56-65545
  SSL/TLS    : $ssl
  UDPGW      : 7100-7300
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  GET wss://bug.com/ HTTP/1.1[crlf]Host: [host] [crlf]Upgrade: websocket[crlf][crlf]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
)

echo -e "$output" > /root/output.txt
