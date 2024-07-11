#!/bin/bash

clear
source /var/lib/ssnvpn-pro/ipvps.conf
domain=$(cat /etc/xray/domain)
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " ${COLBG1}         • CREATE VMESS USER •          ${NC} "
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
tls="$(cat ~/log-install.txt | grep -w "Vmess TLS" | cut -d: -f2|sed 's/ //g')"
none="$(cat ~/log-install.txt | grep -w "Vmess None TLS" | cut -d: -f2|sed 's/ //g')"

# Mengambil data dari file data.txt
user=$(sed -n '1p' data.txt)
masaaktif=$(sed -n '2p' data.txt)

if [ -z $user ]; then
    echo -e " [Error] Username cannot be empty "
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m" 
    echo ""
    read -n 1 -s -r -p "   Press any key to back on menu"
    menu
fi

CLIENT_EXISTS=$(grep -w $user /etc/xray/config.json | wc -l)

if [[ ${CLIENT_EXISTS} == '1' ]]; then
    clear
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e " ${COLBG1}         • CREATE VMESS USER •          ${NC} "
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e " Please choose another name."
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m" 
    read -n 1 -s -r -p "   Press any key to back on menu"
    menu
fi

uuid=$(cat /proc/sys/kernel/random/uuid)
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")

sed -i '/#vmess$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","alterId": '"0"',"email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vmessgrpc$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","alterId": '"0"',"email": "'""$user""'"' /etc/xray/config.json

asu=$(cat <<EOF
{
    "v": "2",
    "ps": "${user}",
    "add": "${domain}",
    "port": "443",
    "id": "${uuid}",
    "aid": "0",
    "net": "ws",
    "path": "/vmess",
    "type": "none",
    "host": "${domain}",
    "tls": "tls"
}
EOF
)

ask=$(cat <<EOF
{
    "v": "2",
    "ps": "${user}",
    "add": "${domain}",
    "port": "80",
    "id": "${uuid}",
    "aid": "0",
    "net": "ws",
    "path": "/vmess",
    "type": "none",
    "host": "${domain}",
    "tls": "none"
}
EOF
)

grpc=$(cat <<EOF
{
    "v": "2",
    "ps": "${user}",
    "add": "${domain}",
    "port": "443",
    "id": "${uuid}",
    "aid": "0",
    "net": "grpc",
    "path": "vmess-grpc",
    "type": "none",
    "host": "${domain}",
    "tls": "tls"
}
EOF
)

vmesslink1="vmess://$(echo $asu | base64 -w 0)"
vmesslink2="vmess://$(echo $ask | base64 -w 0)"
vmesslink3="vmess://$(echo $grpc | base64 -w 0)"
systemctl restart xray > /dev/null 2>&1
service cron restart > /dev/null 2>&1

clear
output=$(cat <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━
  • CREATE VMESS USER •     
━━━━━━━━━━━━━━━━━━━━━━━━━━━
Remarks       : ${user}
Expired On    : $exp
Domain        : ${domain}
Port TLS      : ${tls}
Port none TLS : ${none}
Port  GRPC    : ${tls}
id            : ${uuid}
alterId       : 0
Security      : auto
Network       : ws
Path          : /vmess
Path WSS      : wss://bug.com/vmess
ServiceName   : vmess-grpc
━━━━━━━━━━━━━━━━━━━━━━━━━━━
Link TLS : 
${vmesslink1}

Link none TLS : 
${vmesslink2}

Link GRPC : 
${vmesslink3}
━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
)

echo -e "$output" > /root/output.txt
