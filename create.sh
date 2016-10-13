#!/bin/bash -eux

ns="${1}"
namespace="--namespace=${ns}"

kubectl create namespace "${ns}"
kubectl create "${namespace}" --filename="pods.yaml"

until [ "3" -eq "$(kubectl get pods "${namespace}" | grep -c Running)" ] ; do sleep 1 ; done

kubectl_exec() {
  pod="$1" ; cmd="$2" ; shift 2 ; args=("$@")
  kubectl exec "${namespace}" --stdin --tty "${pod}" "${cmd}" -- "${args[@]}"
}

for n in "master-00" "node-01" "node-02" ; do
  kubectl_exec "${n}" systemctl start kubelet docker
done

token="--token=d9e800.955fc7f8f87970e6"

env=(
  "KUBE_HYPERKUBE_IMAGE=gcr.io/kubeadm/hyperkube-amd64:test-master-6df609e5a0d22c481222030e36f6ed6cf26e80cf-30"
)

kubectl_exec "master-00" env "${env[@]}" kubeadm init "${token}"
kubectl_exec "master-00" kubectl get nodes --output=wide
master_ip="$(kubectl get pod "${namespace}" master-00 --output="go-template={{.status.podIP}}")"

for n in "node-01" "node-02" ; do
  kubectl_exec "${n}" kubeadm join "${token}" "${master_ip}"
done
