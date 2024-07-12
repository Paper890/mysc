#!/bin/bash

# Minta token bot dan chat ID dari pengguna
echo -e ••• BOT SETUP FOR MANAGE VPN ON TELEGRAM •••
read -p "Masukkan Token Bot Telegram Anda: " BOT_TOKEN
read -p "Masukkan ChatID Telegram Anda: " CHAT_ID


# Perbarui paket dan instal Python3-pip jika belum ada
apt-get update
apt-get install -y python3-pip

# Instal modul Python yang diperlukan
pip3 install requests
pip3 install schedule
pip3 install pyTelegramBotAPI

# Buat direktori proyek
cd
mkdir -p sanbot
cd sanbot

# Buat file script python
cat <<EOF > sanbot.py
import telebot
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton
import os
import subprocess
import random
import string
import re
import shutil
import zipfile
import requests
import schedule
import time
import threading
from datetime import datetime

# Masukkan token bot Anda di sini
TOKEN = '${BOT_TOKEN}'
chat_id = "${CHAT_ID}"

bot = telebot.TeleBot(TOKEN)

# Kamus untuk menyimpan data sementara
user_data = {}

# Fungsi untuk menghapus file lama jika ada
def delete_old_file(file_path):
    if os.path.exists(file_path):
        os.remove(file_path)

# Fungsi untuk menjalankan skrip shell
def run_shell_script(script_path):
    result = subprocess.run(['bash', script_path], capture_output=True, text=True)
    return result.stdout

# Fungsi untuk menjalankan perintah shell langsung
def run_shell_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    return result.stdout

# Fungsi untuk membaca output dari file output.txt
def read_output_file(output_file):
    if os.path.exists(output_file):
        with open(output_file, 'r') as file:
            return file.read()
    return "Output file not found."

# Fungsi untuk menambahkan huruf acak kapital di belakang username
def add_random_capital_letter(username):
    return username + random.choice(string.ascii_uppercase)

# Fungsi untuk mendapatkan jumlah akun
def get_account_counts(config_path='/etc/xray/config.json', passwd_path='/etc/passwd'):
    # Baca file konfigurasi xray
    with open(config_path, 'r') as file:
        config_data = file.read()

    # Hitung akun VMESS
    vmess_count = len(re.findall(r'^### ', config_data, re.MULTILINE))
    vmess_accounts = vmess_count // 2

    # Hitung akun VLESS
    vless_count = len(re.findall(r'^#& ', config_data, re.MULTILINE))
    vless_accounts = vless_count // 2

    # Hitung akun TROJAN
    trojan_count = len(re.findall(r'^#! ', config_data, re.MULTILINE))
    trojan_accounts = trojan_count // 2

    # Hitung akun SSH
    with open(passwd_path, 'r') as file:
        passwd_data = file.readlines()

    ssh_count = sum(1 for line in passwd_data if int(line.split(':')[2]) >= 1000 and line.split(':')[0] != "nobody")

    return vless_accounts, vmess_accounts, ssh_count, trojan_accounts

# Fungsi untuk menampilkan menu utama
def main_menu():
    markup = InlineKeyboardMarkup()
    markup.row_width = 2
    markup.add(InlineKeyboardButton("SSH/OVPN MANAGER", callback_data="SSH"),
               InlineKeyboardButton("VMESS MANAGER", callback_data="VMESS"),
               InlineKeyboardButton("VLESS MANAGER", callback_data="VLESS"),
               InlineKeyboardButton("TROJAN MANAGER", callback_data="TROJAN"),
               InlineKeyboardButton("REBOOT VPS", callback_data="REBOOT"),
               InlineKeyboardButton("RESTART SERVICE", callback_data="RESTART"))
    return markup

# Fungsi untuk menampilkan keyboard baru setelah memilih SSH
def ssh_options():
    markup = InlineKeyboardMarkup()
    markup.row_width = 1
    markup.add(InlineKeyboardButton("NEW ACCOUNT", callback_data="SSH_NEW"),
               InlineKeyboardButton("DELETE ACCOUNT", callback_data="SSH_DELETE"),
               InlineKeyboardButton("RENEW ACCOUNT", callback_data="SSH_RENEW"))
    return markup

# Fungsi untuk menampilkan keyboard baru setelah memilih VMESS
def vmess_options():
    markup = InlineKeyboardMarkup()
    markup.row_width = 1
    markup.add(InlineKeyboardButton("NEW ACCOUNT", callback_data="VMESS_NEW"),
               InlineKeyboardButton("DELETE ACCOUNT", callback_data="VMESS_DELETE"),
               InlineKeyboardButton("RENEW ACCOUNT", callback_data="VMESS_RENEW"))
    return markup

# Fungsi untuk menampilkan keyboard baru setelah memilih VLESS
def vless_options():
    markup = InlineKeyboardMarkup()
    markup.row_width = 1
    markup.add(InlineKeyboardButton("NEW ACCOUNT", callback_data="VLESS_NEW"),
               InlineKeyboardButton("DELETE ACCOUNT", callback_data="VLESS_DELETE"),
               InlineKeyboardButton("RENEW ACCOUNT", callback_data="VLESS_RENEW"))
    return markup

# Fungsi untuk menampilkan keyboard baru setelah memilih TROJAN
def trojan_options():
    markup = InlineKeyboardMarkup()
    markup.row_width = 1
    markup.add(InlineKeyboardButton("NEW ACCOUNT", callback_data="TROJAN_NEW"),
               InlineKeyboardButton("DELETE ACCOUNT", callback_data="TROJAN_DELETE"),
               InlineKeyboardButton("RENEW ACCOUNT", callback_data="TROJAN_RENEW"))
    return markup

# Handle untuk command /start
@bot.message_handler(commands=['start'])
def send_welcome(message):
    vless_accounts, vmess_accounts, ssh_count, trojan_accounts = get_account_counts()
    account_info = (
        f"⚡SSH Accounts       : {ssh_count}\n"
        f"⚡VMESS Accounts    : {vmess_accounts}\n"
        f"⚡VLESS Accounts     : {vless_accounts}\n"
        f"⚡TROJAN Accounts    : {trojan_accounts}\n\n"
        f"By ❤️ San"
    )
    bot.send_message(message.chat.id, f"•• 🤖 Bot VPN Manager 🤖 ••\n\n{account_info}", reply_markup=main_menu())

# Handle untuk callback query dari InlineKeyboardButton
@bot.callback_query_handler(func=lambda call: True)
def callback_query(call):
    chat_id = call.message.chat.id
    data = call.data
    
    if data == "SSH":
        bot.edit_message_reply_markup(chat_id, call.message.message_id, reply_markup=ssh_options())
    elif data == "VMESS":
        bot.edit_message_reply_markup(chat_id, call.message.message_id, reply_markup=vmess_options())
    elif data == "VLESS":
        bot.edit_message_reply_markup(chat_id, call.message.message_id, reply_markup=vless_options())
    elif data == "TROJAN":
        bot.edit_message_reply_markup(chat_id, call.message.message_id, reply_markup=trojan_options())
    elif data == "REBOOT":
        bot.send_message(chat_id, "VPS akan segera di-reboot.")
        output = run_shell_command("reboot")
        bot.send_message(chat_id, f"Output dari perintah reboot:\n{output}")
    elif data == "RESTART":
        bot.send_message(chat_id, "Layanan akan segera di-restart.")
        services = [
            "systemctl daemon-reload",
            "systemctl restart ssh",
            "systemctl restart squid",
            "systemctl restart openvpn",
            "systemctl restart nginx",
            "systemctl restart dropbear",
            "systemctl restart ws-dropbear",
            "systemctl restart ws-stunnel",
            "systemctl restart stunnel4",
            "systemctl restart xray",
            "systemctl restart cron"
        ]
        for service in services:
            output = run_shell_command(service)
            bot.send_message(chat_id, f"Output dari {service}:\n{output}")
    elif data in ["SSH_NEW", "VMESS_NEW", "VLESS_NEW", "TROJAN_NEW"]:
        user_data[chat_id] = {'script': data.split('_')[0].lower() + '_new.sh', 'type': 'new'}
        bot.send_message(chat_id, "Silakan masukkan username:")
        bot.register_next_step_handler_by_chat_id(chat_id, get_username)
    elif data in ["SSH_RENEW", "VMESS_RENEW", "VLESS_RENEW", "TROJAN_RENEW"]:
        user_data[chat_id] = {'script': data.split('_')[0].lower() + '_renew.sh', 'type': 'renew'}
        bot.send_message(chat_id, "Silakan masukkan username:")
        bot.register_next_step_handler_by_chat_id(chat_id, get_username)
    elif data in ["SSH_DELETE", "VMESS_DELETE", "VLESS_DELETE", "TROJAN_DELETE"]:
        user_data[chat_id] = {'script': data.split('_')[0].lower() + '_delete.sh', 'type': 'delete'}
        bot.send_message(chat_id, "Silakan masukkan username:")
        bot.register_next_step_handler_by_chat_id(chat_id, get_username)
    elif data in ['30', '60', '90', '120']:
        handle_duration_selection(call)

# Menerima username
def get_username(message):
    chat_id = message.chat.id
    username = message.text
    if user_data[chat_id]['type'] == 'new':
        username = add_random_capital_letter(username)
    user_data[chat_id]['username'] = username
    
    if user_data[chat_id]['script'] == 'ssh_new.sh':
        bot.send_message(chat_id, "masukkan password:")
        bot.register_next_step_handler(message, get_password)
    elif user_data[chat_id]['type'] == 'delete':
        execute_script(chat_id)
    else:
        ask_for_duration(chat_id)

# Menerima password
def get_password(message):
    chat_id = message.chat.id
    user_data[chat_id]['password'] = message.text
    ask_for_duration(chat_id)

# Menampilkan pilihan masa aktif menggunakan InlineKeyboard
def ask_for_duration(chat_id):
    markup = InlineKeyboardMarkup()
    markup.row_width = 2
    markup.add(
        InlineKeyboardButton("30 hari", callback_data='30'),
        InlineKeyboardButton("60 hari", callback_data='60'),
        InlineKeyboardButton("90 hari", callback_data='90'),
        InlineKeyboardButton("120 hari", callback_data='120')
    )
    bot.send_message(chat_id, "Pilih masa aktif:", reply_markup=markup)

# Menangani callback dari InlineKeyboardButton untuk masa aktif
def handle_duration_selection(call):
    chat_id = call.message.chat.id
    user_data[chat_id]['duration'] = call.data
    
    # Nama file yang akan disimpan
    file_path = 'data.txt'
    
    # Hapus file lama jika ada
    delete_old_file(file_path)
    
    # Simpan data ke file dengan format sederhana
    with open(file_path, 'a') as file:
        file.write(f"{user_data[chat_id]['username']}\n")
        if 'password' in user_data[chat_id]:
            file.write(f"{user_data[chat_id]['password']}\n")
        file.write(f"{user_data[chat_id]['duration']}\n")
        file.write("\n")

    bot.send_message(chat_id, "Data Anda telah disimpan. Terima kasih!")
    
    execute_script(chat_id)

def execute_script(chat_id):
    # Jalankan skrip shell dan dapatkan outputnya
    script_output = run_shell_script(user_data[chat_id]['script'])
    
    # Baca output dari file output.txt
    output_text = read_output_file('output.txt')
    
    # Kirimkan output ke pengguna
  
    bot.send_message(chat_id, f"{output_text}")
    
    # Hapus data dari kamus setelah disimpan
    del user_data[chat_id]
#####
# Lokasi direktori dan file/folder yang ingin disalin
src_dir = "/etc/"
files_to_copy = ["passwd", "group", "shadow", "gshadow"]
folder_to_copy = "xray"
destination_dir = "/tmp/backup"
restore_dir = "/etc/"

def copy_files_and_folder():
    if os.path.exists(destination_dir):
        shutil.rmtree(destination_dir)
    os.makedirs(destination_dir, exist_ok=True)

    for file in files_to_copy:
        shutil.copy2(os.path.join(src_dir, file), destination_dir)

    src_folder_path = os.path.join(src_dir, folder_to_copy)
    dest_folder_path = os.path.join(destination_dir, folder_to_copy)
    shutil.copytree(src_folder_path, dest_folder_path)

def create_zip():
    now = datetime.now()
    zip_filename = os.path.join(destination_dir, f"Tanggal_{now.strftime('%Y-%m-%d')}.zip")
    with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(destination_dir):
            for file in files:
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, destination_dir)
                zipf.write(file_path, arcname)
    return zip_filename

def send_to_telegram(file_path):
    url = f"https://api.telegram.org/bot{bot_token}/sendDocument"
    with open(file_path, 'rb') as f:
        files = {'document': f}
        data = {'chat_id': chat_id, 'caption': 'Backup Succes\nLakukan Restart All Service & Pointing Domain kembali setelah Melakukan Restore'}
        response = requests.post(url, files=files, data=data)
    if response.status_code == 200:
        print("File sent successfully")
    else:
        print(f"Failed to send file: {response.text}")

def job():
    copy_files_and_folder()
    zip_filename = create_zip()
    send_to_telegram(zip_filename)

schedule.every(60).minutes.do(job)

def restore_backup(zip_filepath):
    with zipfile.ZipFile(zip_filepath, 'r') as zip_ref:
        zip_ref.extractall("/tmp/restore")

    for file in ["passwd", "group", "shadow", "gshadow"]:
        shutil.copy2(os.path.join("/tmp/restore", file), restore_dir)

    folder_to_copy = "xray"
    src_folder_path = os.path.join("/tmp/restore", folder_to_copy)
    dest_folder_path = os.path.join(restore_dir, folder_to_copy)

    if os.path.exists(dest_folder_path):
        shutil.rmtree(dest_folder_path)
    shutil.copytree(src_folder_path, dest_folder_path)

    shutil.rmtree("/tmp/restore")

@bot.message_handler(content_types=['document'])
def handle_docs(message):
    try:
        file_info = bot.get_file(message.document.file_id)
        downloaded_file = bot.download_file(file_info.file_path)

        zip_filepath = os.path.join("/tmp", message.document.file_name)
        with open(zip_filepath, 'wb') as new_file:
            new_file.write(downloaded_file)

        restore_backup(zip_filepath)
        os.remove(zip_filepath)

        bot.reply_to(message, "Restore completed successfully.")
    except Exception as e:
        bot.reply_to(message, f"Restore failed: {e}")

# Mengaktifkan bot Telegram
bot_thread = threading.Thread(target=lambda: bot.polling(none_stop=True))
bot_thread.start()

print("Script is running...")

while True:
    schedule.run_pending()
    time.sleep(1)
EOF

###### Install Module ####
wget https://raw.githubusercontent.com/Paper890/mysc/main/bot/ssh_renew.sh && chmod +x ssh_renew.sh
wget https://raw.githubusercontent.com/Paper890/mysc/main/bot/ssh_new.sh && chmod +x ssh_new.sh
wget https://raw.githubusercontent.com/Paper890/mysc/main/bot/ssh_delete.sh && chmod +x ssh_delete.sh
wget https://raw.githubusercontent.com/Paper890/mysc/main/bot/vmess_renew.sh && chmod +x vmess_renew.sh
wget https://raw.githubusercontent.com/Paper890/mysc/main/bot/vmess_new.sh && chmod +x vmess_new.sh
wget https://raw.githubusercontent.com/Paper890/mysc/main/bot/vmess_delete.sh && chmod +x vmess_delete.sh
wget https://raw.githubusercontent.com/Paper890/mysc/main/bot/vmess_renew.sh && chmod +x vmess_renew.sh
wget https://raw.githubusercontent.com/Paper890/mysc/main/bot/vless_new.sh && chmod +x vless_new.sh
wget https://raw.githubusercontent.com/Paper890/mysc/main/bot/vless_delete.sh && chmod +x vless_delete.sh
wget https://raw.githubusercontent.com/Paper890/mysc/main/bot/vless_renew.sh && chmod +x vless_renew.sh
wget https://raw.githubusercontent.com/Paper890/mysc/main/bot/trojan_delete.sh && chmod +x trojan_delete.sh
wget https://raw.githubusercontent.com/Paper890/mysc/main/bot/trojan_new.sh && chmod +x trojan_new.sh
wget https://raw.githubusercontent.com/Paper890/mysc/main/bot/trojan_renew.sh && chmod +x trojan_renew.sh

# Buat file service systemd
cat <<EOF > /etc/systemd/system/sanbot.service
[Unit]
Description=Backup and Restore Bot Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /root/sanbot/sanbot.py
WorkingDirectory=/root/sanbot/
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
