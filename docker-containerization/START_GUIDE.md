# Start guide — Docker

This folder is a **complete lab**: commands, `Dockerfile`, `docker-compose.yml`, and config files.

---

## What you are building

Imagine a **small restaurant**:

1. **Guests (browsers, Postman)** only knock on the **front door**. That door is **Nginx** on port **80**.
2. **Nginx** is the **host**: it does **not** cook the food. It **takes the order** and passes it to the **kitchen**.
3. The **kitchen** is your **Flask app**. We run **two kitchens** (`backend-1` and `backend-2`) that cook the **same menu**. Nginx **takes turns** sending orders to kitchen A, then B, then A… That is **load balancing** (share the work).
4. **MySQL** is a **filing cabinet** where data is stored. The files stay in a **Docker volume** (`mysql_data`). If you throw away the **container** but keep the **volume**, the **data is still there** when you start a new container.
5. **Portainer** is an **optional security camera**: a web page to **see** your containers, **logs**, and **stats** — helpful when you stress-test.

---

## Big picture

```
  Browser / Postman
         │
         ▼
    ┌─────────┐     round-robin      ┌────────────┐   ┌────────────┐
    │  Nginx  │ ───────────────────► │ backend-1  │   │ backend-2  │
    │  :80    │                      │ Flask :5000│   │ Flask :5000│
    └─────────┘                      └────────────┘   └────────────┘
         │                                    same app (jokes API + page)
         │
         │  (MySQL is separate; data on disk in a volume)
         ▼
    ┌─────────┐
    │  MySQL  │  ← folder /var/lib/mysql stored in named volume `mysql_data`
    │  :3306  │
    └─────────┘

  Portainer :9000  ← talks to Docker on your machine (not part of the “app path”)
```

---

## What lives in this folder

| File | What it does, in plain English |
|------|--------------------------------|
| **`Dockerfile`** | Recipe to build **our Python image**: start from `python:3.12-slim`, install packages from `requirements.txt`, copy `app.py`, run `python app.py`. |
| **`docker-compose.yml`** | **Start script for many containers at once**: two Flask apps, Nginx, MySQL, Portainer; shared network `app-net`; volumes for MySQL and Portainer. |
| **`nginx.conf`** | Tells Nginx: “send traffic to **backend-1** and **backend-2**” (load balancing). |
| **`app.py`** | The Flask web app (HTML page + `/api/joke`). Each backend returns its **container hostname** so you can **see** which server answered. |
| **`requirements.txt`** | List of Python libraries `pip` must install inside the image. |
| **`init.sql`** | Runs **once** when MySQL starts with an **empty** database folder — creates a demo table and sample rows. |
| **`.env.example`** | Example names/passwords for MySQL. Copy to `.env` if you want to change defaults. |
| **`ASSIGNMENT.md`** | Step-by-step **checkpoint commands** (plain Docker CLI, volumes, networking, compose). |
| **`docker-compose.from-hub.yml`** | Run the stack using a **pre-pulled** image from Docker Hub for both backends (needs `nginx.conf`, `init.sql`). |

**Images pulled from Docker Hub (no login required for public pulls):**

- `nginx:alpine`
- `mysql:8.0`
- `portainer/portainer-ce:latest`

**Images you build locally (no registry required):**

- Built from **`Dockerfile`** — Compose names them automatically (e.g. `docker-containerization-backend-1`).

---

## Prerequisites

- Install **Docker** and **Docker Compose v2** (`docker compose` works).
- Free ports on your machine: **80** (app), **9000** (Portainer). If 80 is busy, change `"80:80"` in `docker-compose.yml` to e.g. `"8080:80"` and open **http://localhost:8080**.

---

## Run the full stack (fastest path)

In a terminal:

```bash
cd docker-containerization

# Optional: custom MySQL passwords
# cp .env.example .env   # then edit .env

docker compose build
docker compose up -d
```

Check everything is up:

```bash
docker compose ps
docker compose logs --tail=50
```

**Open in a browser:**

| What | URL |
|------|-----|
| App (through Nginx) | **http://localhost** |
| Joke API (JSON) | **http://localhost/api/joke** |
| Portainer (first time: create admin user) | **http://localhost:9000** |

Stop the stack (keeps MySQL data in the volume):

```bash
docker compose down
```

Stop and **delete** MySQL data too (careful):

```bash
docker compose down -v
```

---

## What happens when you open http://localhost

1. Your browser talks **only** to **Nginx** (port 80).
2. Nginx reads **`nginx.conf`**, picks **backend-1** or **backend-2**, and forwards the HTTP request to that Flask container on port **5000**.
3. Flask runs **`app.py`** and sends HTML or JSON back. Nginx passes the response to your browser.
4. The **Backend** field on the page (or `container_hostname` in JSON) changes when the **other** kitchen handled the request — so you can **see** load balancing.

MySQL does **not** have to be used by the joke app for the checkpoint; it proves **volumes** and runs **`init.sql`** on first boot.

---

## Build an image tag `my-python-app:v1` (checkpoint)

From this folder:

```bash
docker build -t my-python-app:v1 .
docker run --rm -p 5000:5000 my-python-app:v1
```

Visit **http://127.0.0.1:5000**, then stop with **Ctrl+C**. Inspect layers:

```bash
docker history my-python-app:v1
```

---

## Checkpoint checklist (where to find commands)

| Checkpoint | What to do | Details in |
|------------|------------|------------|
| Docker CLI: pull nginx, run on 8080, exec, restart, remove | Hands-on with **only** Docker commands | **`ASSIGNMENT.md`** §1 |
| Dockerfile `python:3.12-slim`, `app.py`, `requirements.txt`, `python app.py` | **`Dockerfile`** in this folder | **`ASSIGNMENT.md`** §2 |
| MySQL + volume + create data + recreate container | Standalone example + Compose **`mysql` + `mysql_data`** | **`ASSIGNMENT.md`** §3 + **`init.sql`** |
| Custom network `internal-net`, ping, curl | Standalone containers | **`ASSIGNMENT.md`** §4 |
| Compose: Flask + Nginx + network + `up -d` + logs + ps | **`docker-compose.yml`** | This guide + **`ASSIGNMENT.md`** §5 |

---

## Environment variables (MySQL)

Compose uses these (defaults in `docker-compose.yml`; override with a **`.env`** file next to `docker-compose.yml`):

| Variable | Default (if unset) |
|----------|---------------------|
| `MYSQL_ROOT_PASSWORD` | `rootsecret` |
| `MYSQL_DATABASE` | `demoapp` |
| `MYSQL_USER` | `appuser` |
| `MYSQL_PASSWORD` | `appsecret` |

See **`.env.example`**.

---

## Docker Hub: push, then pull and run somewhere else

**Push** a locally built image (use **`username/repository:tag`**, not a bare name, or Hub rejects the push):

```bash
docker build -t my-python-app:v1 .
docker tag my-python-app:v1 YOUR_USERNAME/my-python-app:v1
docker login
docker push YOUR_USERNAME/my-python-app:v1
```

**Pull** and **run** a single container (good for proving the image works on a clean machine):

```bash
docker pull YOUR_USERNAME/my-python-app:v1
docker run --rm -p 5000:5000 YOUR_USERNAME/my-python-app:v1
```

Open **http://127.0.0.1:5000**. Stop with **Ctrl+C**.

**Concrete example:**

```bash
docker pull kirigwidev/my-python-app:v1
docker run --rm -p 5000:5000 kirigwidev/my-python-app:v1
```

One container = **one** backend (no Nginx **load balancing**). For jokes from MySQL or the full proxy stack, use **`docker compose`** or **`docker compose -f docker-compose.from-hub.yml up -d`** with **`nginx.conf`** and **`init.sql`** present.

The Hub page lists tags and the **`docker pull`** line, e.g. **`https://hub.docker.com/r/YOUR_USERNAME/my-python-app`**.

---

## Troubleshooting (short)

| Problem | Try |
|---------|-----|
| Port 80 in use | Change to `"8080:80"` in `docker-compose.yml` |
| MySQL keeps restarting | Wait 30s on first start; check `docker compose logs mysql` |
| `init.sql` did not run | Volume already had data — only runs on **first** empty volume; use `docker compose down -v` to reset (deletes DB data) |
| Cannot see load balancing | Refresh `/api/joke` many times; check **Backend** / `container_hostname` |

---

## Summary

- **Nginx** = front door + traffic cop between two identical Flask apps.  
- **Volumes** = MySQL data survives container restarts.  
- **Network** = containers talk by **service name** (`backend-1`, `mysql`, …).  
- **Compose** = one file to start the whole stack.  

Checkpoint-style commands live in **`ASSIGNMENT.md`**; this **`START_GUIDE.md`** is the short overview and runbook.
