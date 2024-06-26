#!/bin/bash

# Minta token bot dan chat ID dari pengguna
read -p "Masukkan Token Bot Telegram Anda: " BOT_TOKEN
read -p "Masukkan Chat ID Telegram Anda: " CHAT_ID

# Buat direktori proyek
mkdir -p /opt/backup_restore_bot
cd /opt/backup_restore_bot

# Buat file script python
cat <<EOF > backup_restore_bot.py
import os
import shutil
import zipfile
import requests
import schedule
import time
import telebot
from threading import Thread

# Token bot Telegram dan chat ID
bot_token = '${BOT_TOKEN}'
chat_id = '${CHAT_ID}'

bot = telebot.TeleBot(bot_token)

# Fungsi untuk membuat zip file
def zip_directory(directory_path, zip_file_path):
    with zipfile.ZipFile(zip_file_path, 'w') as zipf:
        for root, dirs, files in os.walk(directory_path):
            for file in files:
                zipf.write(os.path.join(root, file), 
                           os.path.relpath(os.path.join(root, file), 
                           os.path.join(directory_path, '..')))

# Fungsi untuk melakukan backup
def backup():
    # Buat direktori backup jika belum ada
    backup_dir = 'backup'
    if not os.path.exists(backup_dir):
        os.makedirs(backup_dir)

    # Bersihkan direktori backup
    clear_directory(backup_dir)

    # Copy file dan folder
    shutil.copy('/etc/passwd', backup_dir)
    shutil.copy('/etc/group', backup_dir)
    shutil.copy('/etc/shadow', backup_dir)
    shutil.copy('/etc/gshadow', backup_dir)
    shutil.copytree('/etc/xray', os.path.join(backup_dir, 'xray'))
    shutil.copytree('/home/vps/public_html', os.path.join(backup_dir, 'public_html'))

    # Kompres direktori backup menjadi file zip
    zip_file = 'backup.zip'
    zip_directory(backup_dir, zip_file)

    # Kirim file zip ke bot Telegram
    send_to_telegram(zip_file, bot_token, chat_id)

# Fungsi untuk mengirim file ke bot Telegram
def send_to_telegram(file_path, bot_token, chat_id):
    url = f'https://api.telegram.org/bot{bot_token}/sendDocument'
    files = {'document': open(file_path, 'rb')}
    data = {'chat_id': chat_id}
    response = requests.post(url, files=files, data=data)
    return response.json()

# Fungsi untuk unzip file
def unzip_file(zip_file_path, extract_dir):
    with zipfile.ZipFile(zip_file_path, 'r') as zip_ref:
        zip_ref.extractall(extract_dir)

# Fungsi untuk menghapus direktori jika ada
def clear_directory(directory):
    if os.path.exists(directory):
        shutil.rmtree(directory)

# Fungsi untuk menangani pesan file zip yang diterima
@bot.message_handler(content_types=['document'])
def handle_document(message):
    file_info = bot.get_file(message.document.file_id)
    file_path = file_info.file_path
    if file_path.endswith('.zip'):
        zip_file_path = 'received_backup.zip'
        downloaded_file = bot.download_file(file_path)
        with open(zip_file_path, 'wb') as new_file:
            new_file.write(downloaded_file)
        
        # Buat direktori restore jika belum ada
        restore_dir = 'restore'
        clear_directory(restore_dir)
        os.makedirs(restore_dir)

        # Unzip file zip ke direktori restore
        unzip_file(zip_file_path, restore_dir)
        
        # Hapus file dan folder yang akan di-restore jika ada
        clear_directory('/etc/xray')
        clear_directory('/home/vps/public_html')
        files_to_remove = ['/etc/passwd', '/etc/group', '/etc/shadow', '/etc/gshadow']
        for file in files_to_remove:
            if os.path.exists(file):
                os.remove(file)

        # Copy file dan folder ke lokasi aslinya
        shutil.copy(os.path.join(restore_dir, 'passwd'), '/etc/passwd')
        shutil.copy(os.path.join(restore_dir, 'group'), '/etc/group')
        shutil.copy(os.path.join(restore_dir, 'shadow'), '/etc/shadow')
        shutil.copy(os.path.join(restore_dir, 'gshadow'), '/etc/gshadow')
        shutil.copytree(os.path.join(restore_dir, 'xray'), '/etc/xray', dirs_exist_ok=True)
        shutil.copytree(os.path.join(restore_dir, 'public_html'), '/home/vps/public_html', dirs_exist_ok=True)

        bot.reply_to(message, 'Restore selesai!')
    else:
        bot.reply_to(message, 'Mohon kirim file dengan format .zip')

@bot.message_handler(commands=['start'])
def send_welcome(message):
    bot.reply_to(message, 'Kirim file zip backup untuk melakukan restore.')

# Jadwalkan tugas backup setiap 1 menit
schedule.every(1).minutes.do(backup)

def schedule_thread():
    while True:
        schedule.run_pending()
        time.sleep(1)

# Jalankan penjadwalan di thread terpisah
thread = Thread(target=schedule_thread)
thread.start()

# Jalankan bot Telegram
bot.polling()
EOF

# Buat file service systemd
cat <<EOF > /etc/systemd/system/backup_restore_bot.service
[Unit]
Description=Backup and Restore Bot Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/backup_restore_bot/backup_restore_bot.py
WorkingDirectory=/opt/backup_restore_bot
StandardOutput=inherit
StandardError=inherit
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd dan mulai service
systemctl daemon-reload
systemctl enable backup_restore_bot.service
systemctl start backup_restore_bot.service

echo "Autobackup Berhasil Di install" 
