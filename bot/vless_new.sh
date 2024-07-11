domain=$(cat /etc/xray/domain)
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " ${COLBG1}          • CREATE VLESS USER •         ${NC} "
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
tls="$(cat ~/log-install.txt | grep -w "Vless TLS" | cut -d: -f2|sed 's/ //g')"
none="$(cat ~/log-install.txt | grep -w "Vless None TLS" | cut -d: -f2|sed 's/ //g')"
until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
		user=$(sed -n '1p' data.txt)
        if [ -z $user ]; then
echo -e " [Error] Username cannot be empty "
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""
read -n 1 -s -r -p "   Press any key to back on menu"
menu
fi
		CLIENT_EXISTS=$(grep -w $user /etc/xray/config.json | wc -l)

if [[ ${CLIENT_EXISTS} == '1' ]]; then
echo -e " Please choose another name."
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""
read -n 1 -s -r -p "   Press any key to back on menu"
menu
fi
done

uuid=$(cat /proc/sys/kernel/random/uuid)
masaaktif=$(sed -n '2p' data.txt)
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
sed -i '/#vless$/a\#& '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessgrpc$/a\#& '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
vlesslink1="vless://${uuid}@${domain}:$tls?path=/vlessws&security=tls&encryption=none&type=ws#${user}"
vlesslink2="vless://${uuid}@${domain}:$none?path=/vlessws&encryption=none&type=ws#${user}"
vlesslink3="vless://${uuid}@${domain}:$tls?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=bug.com#${user}"
systemctl restart xray
clear

output=$(cat <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━
   • CREATE VLESS USER •
━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Remarks       : ${user}
 Expired On    : $exp
 Domain        : ${domain}
 port TLS      : $tls
 port none TLS : $none
 id            : ${uuid}
 Encryption    : none
 Network       : ws
 Path          : /vless
 Path WSS      : wss://bug.com/vless
 Path          : vless-grpc
━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Link TLS :
 ${vlesslink1}

 Link none TLS :
 ${vlesslink2}

 Link GRPC :
 ${vlesslink3}
━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
)
echo -e "$output" > /root/output.txt