#!/bin/bash

# run.sh
# Script untuk menjalankan aplikasi frontend React dan backend FastAPI secara bersamaan di tab terminal baru.
# Jalankan script ini setelah ./init.sh berhasil dijalankan.
# Letakkan script ini di root repositori induk (misalnya, my-fullstack-app/).

# --- Konfigurasi ---
FRONTEND_DIR="react-frontend-auth"
BACKEND_DIR="python-fast-api-auth"

# --- Fungsi untuk membersihkan port yang digunakan ---
cleanup_port() {
  PORT=$1
  echo "Memeriksa proses yang berjalan di port $PORT..."
  # Temukan PID yang menggunakan port
  PID=$(lsof -t -i:"$PORT")
  if [ -n "$PID" ]; then
    echo "Proses dengan PID $PID ditemukan di port $PORT. Menghentikan..."
    kill -9 "$PID" # Menghentikan proses secara paksa
    echo "Proses di port $PORT dihentikan."
  else
    echo "Tidak ada proses yang ditemukan di port $PORT."
  fi
}

# --- Jalankan Backend FastAPI di tab terminal baru ---
echo "Memulai Backend FastAPI di tab terminal baru..."
# Bersihkan port backend sebelum memulai
cleanup_port 8000

# Pastikan virtual environment ada sebelum mencoba mengaktifkannya
if [ ! -d "$BACKEND_DIR/venv" ]; then
  echo "Error: Virtual environment backend tidak ditemukan di $BACKEND_DIR/venv."
  echo "Silakan jalankan ./init.sh terlebih dahulu."
  exit 1
fi

# Jalankan Uvicorn di tab baru
gnome-terminal --tab --title="FastAPI Backend" -- bash -c "echo 'Menjalankan FastAPI Backend...'; cd \"$BACKEND_DIR\" && source venv/bin/activate && uvicorn main:app --reload --host 0.0.0.0 --port 8000; exec bash" &

# --- Jalankan Frontend React di tab terminal baru ---
echo "Memulai Frontend React di tab terminal baru..."
# Bersihkan port frontend sebelum memulai
cleanup_port 3000

# Pastikan node_modules ada sebelum mencoba menjalankannya
if [ ! -d "$FRONTEND_DIR/node_modules" ]; then
  echo "Error: Dependensi frontend tidak ditemukan di $FRONTEND_DIR/node_modules."
  echo "Silakan jalankan ./init.sh terlebih dahulu."
  exit 1
fi

# Jalankan npm start di tab baru
gnome-terminal --tab --title="React Frontend" -- bash -c "echo 'Menjalankan React Frontend...'; cd \"$FRONTEND_DIR\" && npm start; exec bash" &

echo "Kedua aplikasi sedang berjalan di tab terminal baru."
echo "Tutup tab terminal tersebut untuk menghentikan aplikasi."

# Script ini tidak perlu 'wait' atau 'trap' karena proses dijalankan di tab terpisah.
# Proses utama script ini akan selesai setelah meluncurkan tab.
