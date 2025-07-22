#!/bin/bash

# init.sh
# Script untuk menginisialisasi dan menginstal dependensi untuk frontend React dan backend FastAPI.
# Jalankan script ini sekali setelah meng-clone repositori induk dan submodul.
# Letakkan script ini di root repositori induk (misalnya, my-fullstack-app/).

# --- Konfigurasi ---
FRONTEND_DIR="react-frontend-auth"
BACKEND_DIR="python-fast-api-auth"
# BACKEND_VENV_DIR="$BACKEND_DIR/venv" # Variabel ini tidak lagi diperlukan karena kita akan cd ke direktori backend

echo "Memulai inisialisasi proyek fullstack..."

# --- Inisialisasi dan Perbarui Submodul (Jika Belum) ---
echo "Memperbarui submodul Git..."
git submodule update --init --recursive
if [ $? -ne 0 ]; then
  echo "Gagal menginisialisasi atau memperbarui submodul. Pastikan URL submodul benar."
  exit 1
fi
echo "Submodul diperbarui."

# --- Setup Backend FastAPI ---
echo "Menyiapkan Backend FastAPI..."
(
  cd "$BACKEND_DIR" || { echo "Direktori backend tidak ditemukan. Keluar."; exit 1; }
  echo "Membuat virtual environment backend..."
  python3 -m venv venv || { echo "Gagal membuat virtual environment. Pastikan Python 3 terinstal."; exit 1; }
  
  echo "Mengaktifkan virtual environment backend dan menginstal dependensi..."
  # Path yang diperbaiki: Karena kita sudah berada di $BACKEND_DIR, cukup gunakan 'venv/bin/activate'
  source venv/bin/activate || { echo "Gagal mengaktifkan virtual environment."; exit 1; }
  pip install --upgrade pip
  pip install -r requirements.txt || { echo "Gagal menginstal dependensi backend dari requirements.txt."; exit 1; }
  
  echo "Dependensi backend terinstal."
  # Pastikan file .env sudah diatur di direktori backend secara manual
  if [ ! -f .env ]; then
    echo "Peringatan: File .env tidak ditemukan di $BACKEND_DIR. Pastikan Anda membuatnya dengan SECRET_KEY dan variabel lainnya."
  fi
) || exit 1 # Keluar jika ada error di sub-shell

# --- Setup Frontend React ---
echo "Menyiapkan Frontend React..."
(
  cd "$FRONTEND_DIR" || { echo "Direktori frontend tidak ditemukan. Keluar."; exit 1; }
  echo "Menginstal dependensi frontend..."
  npm install || { echo "Gagal menginstal dependensi frontend. Pastikan Node.js dan npm terinstal."; exit 1; }
  echo "Dependensi frontend terinstal."
) || exit 1 # Keluar jika ada error di sub-shell

echo "Inisialisasi proyek fullstack selesai!"
echo "Sekarang Anda dapat menjalankan aplikasi dengan: ./run.sh"
