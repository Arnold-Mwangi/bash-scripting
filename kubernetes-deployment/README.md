# kubernetes-deployment

Node.js app on Kubernetes — Deployment, Service, Ingress, ConfigMap, Secret, PV/PVC, HPA, and `kubectl` monitoring. Deploy, scale, and observe a stateful web workload end to end.

- **[START_GUIDE.md](START_GUIDE.md)** — cluster setup, image build/push, manifests, UI access  
- **[CHECKPOINT.md](CHECKPOINT.md)** — implementation scope and verification steps  
- **App:** Express in `app/` — env from ConfigMap/Secret, visit data on a mounted volume  
- **Manifests:** `k8s/` — `kubectl apply -f k8s/`

## Quick start (Minikube)

```bash
minikube start
minikube addons enable ingress metrics-server

eval $(minikube docker-env)
docker build -t k8s-demo-app:v1 .
# For local daemon only, set deployment image: k8s-demo-app:v1

kubectl apply -f k8s/
kubectl port-forward svc/demo-app-service 8080:80
# http://localhost:8080
```

Docker Hub image: `kirigwidev/k8s-demo-app:v1` (`k8s/deployment.yaml`). Registry auth via `docker login` only — never in manifests.

Ingress (after addon + hosts entry):

```bash
echo "$(minikube ip) demo-app.local" | sudo tee -a /etc/hosts
# http://demo-app.local
```
