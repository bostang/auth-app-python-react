# Authentication App using Python (FastAPI) & React.js

Sebuah parent repository untuk aplikasi sederhana (frontend + backend) untuk autentikasi (register + login) menggunakan React.js untuk frontend dan juga Python FastAPI untuk backend.

## Cara Menjalankan

### Otomatis

> script untuk instalasi aplikasi (frontend, backend) yaitu `init.sh` dan menjalankan aplikasi secara otomatis `run.sh` telah disipakan.

```bash
# lakukan sekali saja untuk menginstall library & dependency frontend dan backend
./init.sh

# untuk menjalankan aplikasi
./run.sh

# akses frontend
```

### Manual

- **Backend**
  - pindah ke direktori `python-fast-api-auth`
  - lakukan `pip install -r requirements.txt`
  - lakukan `uvicorn main:app --reload`
- **Frontend**
  - pindah ke direktori `react-frontend-auth`
  - lakukan `npm install`
  - lakukan `npm start`

## Demonstrasi

- register :

![tampilan-frontend-register](./img/tampilan-frontend-register.png)

- login:

![tampilan-frontend-login](./img/tampilan-frontend-login.png)

- dashboard setelah login

![tampilan-frontend-dashboard](./img/tampilan-frontend-dashboard.png)

- tampilan log di backend:

![tampilan-log-backend](./img/tampilan-log-backend.png)

## Menambahkan submodul

> lakukan ketika belum ada `.gitmodules`

```bash
# menambahkan submodul frontend
git submodule add https://github.com/bostang/react-frontend-auth.git react-frontend-auth

# menambahkan submodul backend
git submodule add https://github.com/bostang/python-fast-api-auth.git python-fast-api-auth

# untuk memperbarui submodul apabila ada perubahan
git submodule update --init --recursive
```

## Catatan CI/CD Pipeline

Agar bisa melakukan CI/CD pipeline secara otomatis pada github workflow, pastikan _repository secrets_ telah didefiniskan tidak hanya di _child repo_ (`python-fast-api-auth`), tetapi juga _parent repo_ (`auth-app-python-react`).

![repo-secrets](./img/repo-secrets.png)

tampilan CI-CD sukses:

![ci-cd-sukses](./img/ci-cd-sukses.png)

## Tutorial Singkat Push Docker image ke registry (Dockerhub)

```bash
# login ke docker
docker login

# lihat image yang sudah dibangun
docker images

# tag docker image
docker tag auth-app-python-react-backend bostang/auth-app-backend:latest
docker tag auth-app-python-react-frontend bostang/auth-app-frontend:latest

# push ke registry
docker push bostang/auth-app-backend:latest
docker push bostang/auth-app-frontend:latest
```


Cara orang lain menggunakan docker image kita:

```bash
# pastikan sudah memiliki docker-compose.yml
docker compose pull # Untuk mengunduh image terbaru
docker compose up -d # Untuk menjalankan kontainer di background
```