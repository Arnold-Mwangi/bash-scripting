#!/usr/bin/env bash
# Generate HTTP load against demo-app pods to spike CPU for HPA testing.
set -euo pipefail

LABEL="${LABEL:-app=demo-app}"
DURATION="${DURATION:-120}"

pods=$(kubectl get pod -l "$LABEL" -o jsonpath='{.items[*].metadata.name}')
if [[ -z "$pods" ]]; then
  echo "No pods found with label $LABEL" >&2
  exit 1
fi

echo "Load test for ${DURATION}s against pods: $pods"
echo "Monitor scaling: kubectl get hpa,pods -l $LABEL -w"

end=$((SECONDS + DURATION))
while (( SECONDS < end )); do
  for pod in $pods; do
    kubectl exec "$pod" -- wget -q -O- http://localhost:3000/api/info >/dev/null 2>&1 || true
  done
done

echo "Done."
