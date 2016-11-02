#!/bin/bash -eux

# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
  DUMMY=1 # "KUBE_HYPERKUBE_IMAGE=gcr.io/kubeadm/hyperkube-amd64:test-master-eec953605e630ebb179dfc3ed0354916235e5a16-36"
)

kubectl_exec "master-00" env "${env[@]}" kubeadm init "${token}"
kubectl_exec "master-00" kubectl get nodes --output=wide
master_ip="$(kubectl get pod "${namespace}" master-00 --output="go-template={{.status.podIP}}")"

for n in "node-01" "node-02" ; do
  kubectl_exec "${n}" kubeadm join "${token}" "${master_ip}"
done
