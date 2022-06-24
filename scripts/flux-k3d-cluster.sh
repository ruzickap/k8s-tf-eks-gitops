#!/usr/bin/env bash

get_variable_from_group_cluster_tfvars() {
  local CLUSTER_PATH="$1" TF_CODE_VARIABLE="$2" VARIABLE_HELPER

  if grep -q "${TF_CODE_VARIABLE}" "${CLUSTER_PATH}/cluster-variables.tfvars"; then
    VARIABLE_HELPER=$(awk -F \" "/^${TF_CODE_VARIABLE}/ { print \$2 }" "${CLUSTER_PATH}/cluster-variables.tfvars")
  else
    VARIABLE_HELPER=$(awk -F \" "/^${TF_CODE_VARIABLE}/ { print \$2 }" "${CLUSTER_PATH}/../group-variables.tfvars")
  fi
  export "${TF_CODE_VARIABLE^^}"="${VARIABLE_HELPER}"
  echo "export ${TF_CODE_VARIABLE^^}=\"${VARIABLE_HELPER}\""
}

##############
# Main
##############

set -euo pipefail

if [[ "$#" -eq 0 ]] || [[ ! -d .git ]]; then
  cat << \EOF
Run in top of the git repository.
Usage: ./scripts/flux-k3d-cluster.sh mgmt02.k8s.use1.dev.proj.aws.mylabs.dev | sh -x"

Required tools:

# Linux tools
apt install -y curl docker.io git snapd

# k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# kubectl
snap install kubectl --classic

# Flux
curl -s https://fluxcd.io/install.sh | bash
EOF
  exit 1
fi

CLUSTER_PATH=$(find clusters/*/*\.*\.* -maxdepth 0 -mindepth 0 -type d -regextype "posix-extended" -regex ".*/${1}\$.*")
echo -e "\n#🍏 Cluster path: ${CLUSTER_PATH}\n"

echo "# ---------------------------------------------------"

echo "export CLUSTER_PATH=\"${CLUSTER_PATH}\""
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "cluster_fqdn"
echo "export CLUSTER_NAME=\"\${CLUSTER_FQDN%%.*}\""
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "cluster_path"
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "email"
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "environment"

echo -e "\n# ------------------------ Code -------------------------"

cat << \EOF
: "${AWS_ACCESS_KEY_ID?}"
: "${AWS_SECRET_ACCESS_KEY?}"
: "${AWS_DEFAULT_REGION?}"

export KUBECONFIG="/tmp/kubeconfig-${CLUSTER_NAME}.conf"

k3d cluster create "${CLUSTER_NAME}" \
  --port "8080:80@loadbalancer" --port "8443:443@loadbalancer" \
  --kubeconfig-update-default=false --wait \
  --k3s-arg "--disable=traefik@all" --k3s-arg "--disable=local-storage@all" --k3s-arg "--disable=metrics-server@all"

k3d kubeconfig write ${CLUSTER_NAME} --overwrite --output "${KUBECONFIG}"

flux install

kubectl create configmap -n flux-system cluster-apps-vars-terraform-configmap \
  --from-literal=CLUSTER_PATH="${CLUSTER_PATH}" \
  --from-literal=CLUSTER_FQDN="${CLUSTER_FQDN}" \
  --from-literal=CLUSTER_NAME="${CLUSTER_NAME}" \
  --from-literal=EMAIL="${EMAIL}" \
  --from-literal=ENVIRONMENT="${ENVIRONMENT}" \
  --from-literal=SLACK_CHANNEL="mylabs" \
  --from-literal=TAGS_INLINE="tag1=test1,tag2=test2,tag3=test3"

kubectl create secret generic aws-creds -n flux-system \
  --from-literal=AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
  --from-literal=AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
  --from-literal=AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}"

flux create source git flux-system \
  --url="$(gh repo view --json url --jq '.url')" \
  --branch="$(git rev-parse --abbrev-ref HEAD)"
flux create kustomization flux-system \
  --source=flux-system \
  --path="${CLUSTER_PATH}/flux/"

# Stop synchronizing the flux-system to allow modification of deployment/kustomize-controller
flux suspend kustomization flux-system
kubectl patch deployment kustomize-controller -n flux-system -p '{"spec": {"template": {"spec": {"containers": [{"name":"manager", "envFrom": [{"secretRef":{"name":"aws-creds"}}] }] }}}}'

echo "export KUBECONFIG=/tmp/kubeconfig-${CLUSTER_NAME}.conf"
echo "http://localhost:8080/dashboard/"
EOF
