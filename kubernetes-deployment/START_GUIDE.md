# Start guide — Kubernetes deployment

How to run this stack on Minikube (local) or on a managed cluster (EKS, GKE, AKS).

## Prerequisites

- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) or a managed cluster
- [Docker](https://docs.docker.com/get-docker/)

```bash
kubectl cluster-info
kubectl get nodes
```

## 1. Cluster and addons

```bash
minikube start
minikube addons enable ingress
minikube addons enable metrics-server
```

`metrics-server` is required for `kubectl top` and the HPA.

## 2. Persistent storage (Minikube + static PV)

`k8s/pv.yaml` uses a `hostPath` volume on the Minikube node. Create the directory inside the VM (quotes run the full command in the guest):

```bash
minikube ssh -- "sudo mkdir -p /data/demo-app && sudo chmod 777 /data/demo-app"
```

On EKS/GKE/AKS: use the cluster StorageClass, remove the static PV, and provision storage with a PVC only.

## 3. Container image

Working directory: `kubernetes-deployment/`

### A — Build into Minikube Docker (no registry)

```bash
eval $(minikube docker-env)
docker build -t k8s-demo-app:v1 .
```

In `k8s/deployment.yaml`:

```yaml
image: k8s-demo-app:v1
imagePullPolicy: Never
```

### B — Docker Hub

```bash
docker build -t kirigwidev/k8s-demo-app:v1 .
docker login
docker push kirigwidev/k8s-demo-app:v1
```

`deployment.yaml` references `kirigwidev/k8s-demo-app:v1`.

## 4. Apply manifests

```bash
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/pv.yaml
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml
```

Or apply the whole directory:

```bash
kubectl apply -f k8s/
```

```bash
kubectl get pods -l app=demo-app
kubectl rollout status deployment/demo-app
```

## 5. Access the application

**Port-forward** (works before Ingress is ready):

```bash
kubectl port-forward svc/demo-app-service 8080:80
```

Open **http://localhost:8080**

**Ingress** (after the addon is enabled and `k8s/ingress.yaml` is applied):

```bash
echo "$(minikube ip) demo-app.local" | sudo tee -a /etc/hosts
```

Open **http://demo-app.local**

The **Record visit** button writes `app-data.json` on the PVC (`/data` in the container).

## 6. HPA load test

```bash
POD=$(kubectl get pod -l app=demo-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec "$POD" -- sh -c 'while true; do wget -q -O- http://localhost:3000/api/info; done' &
```

Or run the helper script:

```bash
./scripts/load-test.sh
```

Watch scaling:

```bash
kubectl get hpa demo-app-hpa -w
kubectl get pods -l app=demo-app -w
```

Stop load generators: `kill %1` or `pkill -f wget`.

## 7. Observe and debug

```bash
kubectl logs -l app=demo-app --tail=50 -f
kubectl top pods -l app=demo-app
kubectl top nodes
kubectl describe deployment demo-app
kubectl describe pod -l app=demo-app
kubectl get events --sort-by='.lastTimestamp'
```

## Clean up

```bash
kubectl delete -f k8s/
minikube stop
```
