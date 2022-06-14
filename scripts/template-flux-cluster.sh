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
  echo -e "\nRun in top of the git repository.\nUsage: ./scripts/template-flux-cluster.sh mgmt02.k8s.use1.dev.proj.aws.mylabs.dev\n"
  exit 1
fi

CLUSTER_PATH=$(find clusters -maxdepth 2 -mindepth 2 -type d -regextype "posix-extended" -regex ".*/${1}\$.*")
echo -e "\n#🍏 Cluster path: ${CLUSTER_PATH}\n"

echo "# ---------------------------------------------------"

echo "export CLUSTER_PATH=\"${CLUSTER_PATH}\""
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "cluster_fqdn"
export CLUSTER_NAME=${CLUSTER_FQDN%%.*}
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "cluster_path"
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "email"
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "environment"

cat << EOF
####################################################################################################################
# kustomize build "${CLUSTER_PATH}/flux/" | envsubst
####################################################################################################################
EOF
kustomize build "${CLUSTER_PATH}/flux/" | envsubst
echo -e "\n\n"

cat << EOF
####################################################################################################################
# kustomize build "${CLUSTER_PATH}/flux/sources" | envsubst
####################################################################################################################
EOF
kustomize build "${CLUSTER_PATH}/flux/sources" | envsubst
echo -e "\n\n"

cat << EOF
####################################################################################################################
# kustomize build "${CLUSTER_PATH}/flux/cluster-apps" | envsubst
####################################################################################################################
EOF
kustomize build "${CLUSTER_PATH}/flux/cluster-apps" | envsubst
