#!/bin/bash

# Redirect all output to /root/output.txt
exec > /root/output.txt 2>&1

echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " ${COLBG1}           • SSH DELETE USERS •         ${NC} "
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"    
echo "   USERNAME        EXP DATE        STATUS"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"  
while read expired
do
    AKUN="$(echo $expired | cut -d: -f1)"
    ID="$(echo $expired | grep -v nobody | cut -d: -f3)"
    exp="$(chage -l $AKUN | grep "Account expires" | awk -F": " '{print $2}')"
    status="$(passwd -S $AKUN | awk '{print $2}' )"
    if [[ $ID -ge 1000 ]]; then
        if [[ "$status" = "L" ]]; then
            printf "%-17s %2s %-17s %2s \n" "   • $AKUN" "$exp     " "LOCKED"
        else
            printf "%-17s %2s %-17s %2s \n" "   • $AKUN" "$exp     " "UNLOCKED"
        fi
    fi
done < /etc/passwd

JUMLAH="$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"  
echo "   Total: $JUMLAH User"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
Pengguna=$(sed -n '1p' data.txt)

if [ -z $Pengguna ]; then
    echo -e "   [Error] Username cannot be empty "
else
    if getent passwd $Pengguna > /dev/null 2>&1; then
        userdel $Pengguna > /dev/null 2>&1
        sed -i "s/$Pengguna//g" /etc/xray/ssh.txt
        echo -e "   [INFO] User $Pengguna was removed."
    else
        echo -e "   [INFO] Failure: User $Pengguna Not Exist."
    fi
fi

echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
