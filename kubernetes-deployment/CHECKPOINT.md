# Checkpoint — Kubernetes web app

Containerized Node.js on Kubernetes: config separation, persistent disk, external routing, CPU autoscaling, and observability via `kubectl`.

## Stack

| Layer | Implementation |
|-------|----------------|
| Runtime | Node.js + Express — `app/server.js` |
| Image | `Dockerfile` → `kirigwidev/k8s-demo-app:v1` |
| State | `app-data.json` on PVC mount (`DATA_DIR=/data`) |

## 1. Cluster

- [x] Minikube (local) — `minikube start`
- [x] `kubectl cluster-info` / `kubectl get nodes` → Ready

## 2. Container image

- [x] App in `app/`
- [x] `docker build -t kirigwidev/k8s-demo-app:v1 .`
- [x] `docker push kirigwidev/k8s-demo-app:v1` (or `eval $(minikube docker-env)` for local-only builds)
- [x] `image:` set in `k8s/deployment.yaml`

## 3. Deployment

- [x] `k8s/deployment.yaml` — 2 replicas, probes, CPU/memory requests
- [x] `kubectl get deployments,pods` — pods Running

## 4. ConfigMap + Secret

- [x] `k8s/configmap.yaml` — `APP_MESSAGE`, `APP_ENV`, `DATA_DIR`
- [x] `k8s/secret.yaml` — `API_SECRET`
- [x] `envFrom` / `secretKeyRef` on the Deployment
- [x] `kubectl exec deploy/demo-app -- env | grep -E 'APP_|API_'`
- [x] `/api/info` → `secretConfigured: true`

## 5. Service + Ingress

- [x] `k8s/service.yaml` — ClusterIP :80 → pod :3000
- [x] Ingress addon + `k8s/ingress.yaml` → `demo-app.local`
- [x] Port-forward: `kubectl port-forward svc/demo-app-service 8080:80` → **http://localhost:8080**
- [x] `curl http://demo-app.local/api/info` (requires `/etc/hosts` entry)

## 6. Persistent volume

- [x] `k8s/pv.yaml` + `k8s/pvc.yaml` — Bound
- [x] Volume mount on Deployment
- [x] Minikube host path:

```bash
minikube ssh -- "sudo mkdir -p /data/demo-app && sudo chmod 777 /data/demo-app"
```

- [x] Visit counter survives pod recycle:

```bash
kubectl delete pod -l app=demo-app
curl http://demo-app.local/api/data
```

## 7. HPA

- [x] `metrics-server` addon enabled
- [x] `k8s/hpa.yaml` — CPU 50%, min 2, max 5
- [x] `./scripts/load-test.sh` — replicas scale up under load, scale down when idle

## 8. Monitoring

- [x] `kubectl logs -l app=demo-app`
- [x] `kubectl top pods` / `kubectl top nodes`
- [x] `kubectl describe pod` + `kubectl get events`

## Manifest map

| File | Role |
|------|------|
| `k8s/configmap.yaml` | Non-sensitive env |
| `k8s/secret.yaml` | `API_SECRET` |
| `k8s/pv.yaml` | PersistentVolume (Minikube hostPath) |
| `k8s/pvc.yaml` | PersistentVolumeClaim |
| `k8s/deployment.yaml` | Workload, probes, PVC mount |
| `k8s/service.yaml` | In-cluster Service |
| `k8s/ingress.yaml` | HTTP routing |
| `k8s/hpa.yaml` | CPU autoscaling |

## Evidence

1. `kubectl get all -l app=demo-app`
2. UI screenshot (`localhost:8080` or `demo-app.local`)
3. `kubectl get pvc,pv` — **Bound**
4. `kubectl get hpa -w` during load test
5. `kubectl top pods -l app=demo-app`

Full command sequence: **[START_GUIDE.md](START_GUIDE.md)**
