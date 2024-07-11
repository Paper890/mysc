import telebot
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton
import os
import subprocess
import random
import string

# Masukkan token bot Anda di sini
TOKEN = '7306410036:AAH6aIiUf4YwWJVd7VMdwLCQOpe84afHeOM'

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

# Menjalankan bot
bot.polling()
