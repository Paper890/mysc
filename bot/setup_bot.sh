#!/bin/bash

# Minta token bot dan chat ID dari pengguna
read -p "Masukkan Token Bot Telegram Anda: " BOT_TOKEN
read -p "Masukkan Chat ID Telegram Anda: " CHAT_ID

# Perbarui paket dan instal Python3-pip jika belum ada
apt-get update
apt-get install -y python3-pip

# Instal modul Python yang diperlukan
pip3 install requests
pip3 install schedule
pip3 install pyTelegramBotAPI

# Buat direktori proyek
cd 

# Buat file script python
cat <<EOF > sanbot.py

EOF

###### Install Module ####

# ssh_new.sh
wget -q https://raw.githubusercontent.com/Paper890/mysc/bot/ssh_new.sh && chmod +x ssh_new.sh

# vmess_new.sh
wget -q https://raw.githubusercontent.com/Paper890/mysc/bot/vmess_new.sh && chmod +x vmess_new.sh

# vless_new.sh
wget -q https://raw.githubusercontent.com/Paper890/mysc/bot/vless_new.sh && chmod +x vless_new.sh

# trojan_new.sh
wget -q https://raw.githubusercontent.com/Paper890/mysc/bot/trojan_new.sh && chmod +x trojan_new.sh

# ssh_delete.sh
wget -q https://raw.githubusercontent.com/Paper890/mysc/bot/ssh_delete.sh && chmod +x ssh_delete.sh

# vmess_delete.sh
wget -q https://raw.githubusercontent.com/Paper890/mysc/bot/vmess_delete.sh && chmod +x vmess_delete.sh

# vless_delete.sh
wget -q https://raw.githubusercontent.com/Paper890/mysc/bot/vless_delete.sh && chmod +x vless_delete.sh

# trojan_delete.sh
wget -q https://raw.githubusercontent.com/Paper890/mysc/bot/trojan_delete.sh && chmod +x trojan_delete.sh

# ssh_renew.sh
wget -q https://raw.githubusercontent.com/Paper890/mysc/bot/ssh_renew.sh && chmod +x ssh_renew.sh

# vmess_renew.sh
wget -q https://raw.githubusercontent.com/Paper890/mysc/bot/vmess_renew.sh && chmod +x vmess_renew.sh

# vless_renew.sh
wget -q https://raw.githubusercontent.com/Paper890/mysc/bot/vless_renew.sh && chmod +x vless_renew.sh

# trojan_renew.sh
wget -q https://raw.githubusercontent.com/Paper890/mysc/bot/trojan_renew.sh && chmod +x trojan_renew.sh


# Buat file service systemd
cat <<EOF > /etc/systemd/system/sanbot.service
[Unit]
Description=Backup and Restore Bot Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/autobackup/sanbot.py
WorkingDirectory=/root/
StandardOutput=inherit
StandardError=inherit
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd dan mulai service
systemctl daemon-reload
systemctl enable sanbot
systemctl start sanbot

echo "Bot Berhasil Di install" 

cd
rm setup_bot.sh
