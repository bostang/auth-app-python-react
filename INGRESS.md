# Tentang Komunikasi Frontend dan Backend

## Cara Menerapkan

```bash
# Install Nginx Ingress Controller di dalam kluster
minikube addons enable ingress

# verifikasi pod ingress controler running
minikube kubectl -- get pods -n ingress-nginx
```

## Latar belakang

Hardcoding IP dan port frontend di `main.py` untuk CORS bukanlah solusi yang praktis atau aman, terutama di lingkungan dinamis seperti Kubernetes di mana NodePort dapat berubah. Mengelola daftar `origins` secara manual di kode adalah mimpi buruk untuk deployment.

Ada beberapa cara yang lebih baik untuk mengatasi ini di Kubernetes:

-----

### 1\. Menggunakan Variabel Lingkungan di Backend FastAPI (Paling Umum dan Direkomendasikan)

Alih-alih meng-hardcode daftar `origins` di `main.py`, kita bisa membuatnya menjadi **variabel lingkungan** yang dibaca oleh aplikasi FastAPI saat startup. Kemudian, kita bisa mengatur nilai variabel lingkungan ini di manifest Kubernetes `backend-deployment.yaml`.

#### Langkah 1: Modifikasi `main.py`

Ubah `main.py` agar membaca daftar origin dari variabel lingkungan. Jika variabel lingkungan tidak disetel, gunakan nilai default yang aman (misalnya, `localhost` untuk pengembangan lokal).

```python
from fastapi import FastAPI, HTTPException, status, Depends
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import Dict
import os ## Import modul os

from models import UserIn, UserOut, Token, UserLogin, User
from auth import get_password_hash, verify_password, create_access_token, get_current_user
from database import get_db

app = FastAPI()

## --- MODIFIKASI DIMULAI DI SINI ---
## Ambil daftar origin dari variabel lingkungan CORS_ORIGINS
## Jika ada beberapa origin, pisahkan dengan koma (misal: "http://origin1,http://origin2")
## Default ke daftar kosong jika variabel lingkungan tidak disetel
cors_origins_str = os.getenv("CORS_ORIGINS", "")
origins = [origin.strip() for origin in cors_origins_str.split(',') if origin.strip()]

## Tambahkan localhost untuk pengembangan lokal jika tidak ada origin lain yang disetel
if not origins: ## Jika variabel lingkungan kosong
    origins = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:5173",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5173",
    ]
## --- MODIFIKASI BERAKHIR DI SINI ---

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

## ... (kode aplikasi lainnya tidak berubah)
```

#### Langkah 2: Bangun Ulang dan Dorong Image Backend

Karena `main.py` diubah, kita perlu membangun ulang image Docker backend dan mendorongnya ke Docker Hub:

```bash
docker build -t bostang/auth-app-backend:latest -f python-fast-api-auth/Dockerfile .
docker push bostang/auth-app-backend:latest
```

#### Langkah 3: Modifikasi `backend-deployment.yaml`

Sekarang, di manifest deployment backend, kita bisa menyetel `CORS_ORIGINS` menggunakan **`valueFrom`** untuk membaca alamat frontend.

Karena IP dan NodePort Minikube berubah-ubah, kita tidak bisa menggunakan `valueFrom` dari Service langsung. Namun, kita bisa **mendapatkan URL eksternal frontend secara dinamis** saat deployment atau menjalankannya secara manual setelah mendapatkan URL-nya.

##### Opsi 1a: Menyetel `CORS_ORIGINS` Secara Manual (paling sederhana untuk Minikube)

Setelah kita menjalankan `minikube service frontend-service -n auth-app` dan mendapatkan URL-nya (misalnya `http://192.168.49.2:32349`), kita bisa menggunakannya di manifest deployment:

```yaml
## backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  namespace: auth-app
  labels:
    app: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: bostang/auth-app-backend:latest
          ports:
            - containerPort: 8000
          env:
            ## Mengambil JWT_SECRET_KEY dari Secret
            - name: JWT_SECRET_KEY
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: JWT_SECRET_KEY
            
            ## Menggunakan Secret untuk membangun DATABASE_URL
            - name: DATABASE_URL
              value: "postgresql+psycopg2://$(DB_USER):$(DB_PASSWORD)@postgres-service:5432/$(DB_NAME)"
            
            ## Mengambil komponen DB User dari Secret
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: DB_USER
            
            ## Mengambil komponen DB Password dari Secret
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: DB_PASSWORD
            
            ## Mengambil komponen DB Name dari Secret
            - name: DB_NAME
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: DB_NAME

            ## Variabel lingkungan lainnya
            - name: JWT_ALGORITHM
              value: "HS256"
            - name: JWT_ACCESS_TOKEN_EXPIRE_MINUTES
              value: "30"
            
            ## --- TAMBAHKAN INI UNTUK CORS_ORIGINS ---
            - name: CORS_ORIGINS
              value: "http://192.168.49.2:32349" ## <--- Ganti dengan URL Minikube frontend kita
            ## --- AKHIR TAMBAHAN ---
```

##### Opsi 1b: Mengizinkan Semua Origin (Hanya untuk Pengembangan/Debugging Minikube)

Untuk mempermudah di Minikube (meskipun **TIDAK UNTUK PRODUKSI**), kita bisa mengizinkan semua origin di FastAPI.

Di `main.py`, set `origins = ["*"]`:

```python
## ... (awal main.py)

app = FastAPI()

## Konfigurasi CORS
## HANYA UNTUK PENGEMBANGAN/DEBUGGING DI LINGKUNGAN AMAN (misal: Minikube)
## JANGAN GUNAKAN INI DI PRODUKSI!
origins = ["*"] 

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

## ... (sisa kode)
```

Kemudian, bangun ulang dan dorong image backend, lalu terapkan ulang deployment backend. Ini akan menyelesaikan masalah CORS tanpa perlu mengelola IP/port.

-----

### 2\. Menggunakan Ingress Controller (Lebih Lanjut, Ideal untuk Produksi)

Untuk solusi yang lebih canggih dan robust, terutama di lingkungan produksi atau jika kita memiliki banyak service, kita akan menggunakan **Ingress Controller** (seperti Nginx Ingress Controller atau Traefik).

Dengan Ingress, kita akan memiliki satu titik masuk (Entrypoint) dengan alamat IP stabil (atau nama domain) yang akan meneruskan lalu lintas ke backend dan frontend kita berdasarkan path atau hostname. Ini menghilangkan kebutuhan untuk NodePort yang berubah-ubah dan menyederhanakan konfigurasi CORS.

#### Cara Kerjanya

1. **Ingress Controller Deployment:** kita menginstal sebuah Ingress Controller di cluster kita.
2. **Ingress Resource:** kita membuat sebuah resource `Ingress` yang mendefinisikan aturan routing:
      * Jika permintaan masuk ke `/api/`, teruskan ke `backend-service:8000`.
      * Jika permintaan masuk ke `/`, teruskan ke `frontend-service:80`.
3. **URL Stabil:** Pengguna mengakses aplikasi kita melalui URL stabil yang dikelola oleh Ingress (misalnya, `http://minikube-ip/` atau `http://your-domain.com/`).
4. **CORS:** Di sisi FastAPI, kita hanya perlu mengizinkan origin dari URL Ingress kita, yang stabil.

#### Contoh Singkat Ingress Resource

```yaml
## app-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: auth-app-ingress
  namespace: auth-app
spec:
  rules:
    - http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port:
                  number: 8000
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

Setelah Ingress diterapkan, `minikube ingress` akan memberikan kita URL untuk mengakses aplikasi.

**Kelebihan Ingress:**

* **URL Stabil:** Pengguna selalu mengakses melalui satu URL stabil.
* **SSL/TLS Termination:** Ingress dapat menangani HTTPS.
* **Routing Lanjutan:** Lebih banyak kontrol atas bagaimana lalu lintas dirutekan.
* **CORS Sederhana:** Origin untuk CORS di backend menjadi stabil.

**Kekurangan Ingress (untuk Minikube):**

* Menambahkan kompleksitas awal (perlu menginstal Ingress Controller).
