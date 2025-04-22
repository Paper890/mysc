#!/bin/bash

# File: setup-tc.sh
# Deskripsi: Skrip otomatis untuk mengatur traffic control (tc) dengan systemd di VPS.

# 1. Tentukan interface jaringan
echo "Mendeteksi interface jaringan..."
INTERFACE=$(ip route | grep default | awk '{print $5}')
if [ -z "$INTERFACE" ]; then
    echo "Tidak dapat mendeteksi interface jaringan. Silakan masukkan nama interface secara manual."
    read -p "Masukkan nama interface (misalnya eth0): " INTERFACE
fi
echo "Interface jaringan yang digunakan: $INTERFACE"

# 2. Buat skrip tc-config.sh
echo "Membuat skrip tc-config.sh..."
cat <<EOF > /usr/local/bin/tc-config.sh
#!/bin/bash

# Interface jaringan
INTERFACE="$INTERFACE"

# Hapus konfigurasi tc sebelumnya (jika ada)
tc qdisc del dev \$INTERFACE root || true

# Tambahkan root qdisc
tc qdisc add dev \$INTERFACE root handle 1: htb default 12

# Tambahkan class utama untuk bandwidth total (misalnya 100 Mbps)
tc class add dev \$INTERFACE parent 1: classid 1:1 htb rate 100mbit ceil 100mbit

# Tambahkan sub-class dengan SFQ untuk pembagian adil
tc class add dev \$INTERFACE parent 1:1 classid 1:10 htb rate 100mbit ceil 100mbit
tc qdisc add dev \$INTERFACE parent 1:10 handle 10: sfq perturb 10
EOF

# Berikan izin eksekusi pada skrip
chmod +x /usr/local/bin/tc-config.sh
echo "Skrip tc-config.sh telah dibuat di /usr/local/bin/tc-config.sh"

# 3. Buat file service systemd
echo "Membuat file service systemd..."
cat <<EOF > /etc/systemd/system/tc-config.service
[Unit]
Description=Traffic Control Configuration
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/tc-config.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

echo "File service systemd telah dibuat di /etc/systemd/system/tc-config.service"

# 4. Reload systemd, aktifkan, dan jalankan service
echo "Mengaktifkan dan menjalankan service tc-config..."
systemctl daemon-reload
systemctl enable tc-config.service
systemctl start tc-config.service

# 5. Verifikasi status service
echo "Memverifikasi status service..."
systemctl status tc-config.service

# 6. Verifikasi aturan tc
echo "Memverifikasi aturan tc..."
tc -s qdisc show dev $INTERFACE
tc -s class show dev $INTERFACE

echo "Setup tc dengan systemd telah selesai!"
