#! /bin/bash
set -e -o pipefail

kubectl apply -n test -f - <<EOF
---
apiVersion: primer.gitops.io/v1alpha1
kind: Export
metadata:
  name: ci
spec:
  method: download
EOF
