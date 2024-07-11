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
import os
import shutil
import zipfile
import requests
import schedule
import time
import threading
import telebot
from datetime import datetime
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton
import subprocess
import random
import string

# Informasi bot Telegram
bot_token = "${BOT_TOKEN}"
chat_id = "${CHAT_ID}"
bot = telebot.TeleBot(bot_token)

# Lokasi direktori dan file/folder yang ingin disalin
src_dir = "/etc/"
files_to_copy = ["passwd", "group", "shadow", "gshadow"]
folder_to_copy = "xray"
destination_dir = "/tmp/backup"
restore_dir = "/etc/"

###################

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

# Fungsi untuk menampilkan menu utama
def main_menu():
    markup = InlineKeyboardMarkup()
    markup.row_width = 2
    markup.add(InlineKeyboardButton("SSH", callback_data="SSH"),
               InlineKeyboardButton("VMESS", callback_data="VMESS"),
               InlineKeyboardButton("VLESS", callback_data="VLESS"),
               InlineKeyboardButton("TROJAN", callback_data="TROJAN"),
               InlineKeyboardButton("REBOOT", callback_data="REBOOT"),
               InlineKeyboardButton("RESTART", callback_data="RESTART"))
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
    bot.send_message(message.chat.id, "Selamat datang! Pilih salah satu opsi di bawah ini:", reply_markup=main_menu())

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
        bot.send_message(chat_id, "Terima kasih. Sekarang masukkan password:")
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
    bot.send_message(chat_id, f"Output dari skrip shell:\n{script_output}")
    bot.send_message(chat_id, f"Informasi dari output.txt:\n{output_text}")
    
    # Hapus data dari kamus setelah disimpan
    del user_data[chat_id]

###################

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

schedule.every(1).minutes.do(job)

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
