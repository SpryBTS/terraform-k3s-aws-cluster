#!/bin/bash
%{ if install_certmanager }
kubectl create namespace cert-manager
# kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
until [ "$(kubectl get namespace cert-manager | grep Active | wc -l)" = "1" ]; do
  echo 'Waiting for cert-manager namespace'
  sleep 2
done

kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v${certmanager_version}/cert-manager.yaml

until [ "$(kubectl get pods --namespace cert-manager | grep Running| wc -l)" = "3" ]; do
  echo 'Waiting for cert-manager'
  sleep 2
done

%{ if install_rancher }
# Split namespace creation and make sure its complete prior to deploying rancher
kubectl create namespace cattle-system

until [ "$(kubectl get namespace cattle-system | grep Active | wc -l)" = "1" ]; do
  echo 'Waiting for cattle-system namespace'
  sleep 2
done

cat <<EOF > /var/lib/rancher/k3s/server/manifests/rancher.yaml
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: rancher
  namespace: kube-system
spec:
  chart: https://releases.rancher.com/server-charts/stable/rancher-${rancher_version}.tgz
  targetNamespace: cattle-system
  valuesContent: |-
    hostname: ${rancher_hostname}
    ingress:
      tls:
        source: letsEncrypt
    letsEncrypt:
      email: ${letsencrypt_email}
      environment: ${letsencrypt_environment}
EOF
%{ endif }
%{ endif }
