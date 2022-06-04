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

CLUSTER_PATH=$(find ./clusters -type d -regextype "posix-extended" -regex ".*/${1}\$.*")
echo -e "\n#🍏 Cluster path: ${CLUSTER_PATH}\n"

echo "# ---------------------------------------------------"

echo "export CLUSTER_PATH=\"${CLUSTER_PATH}\""
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "aws_default_region"
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "aws_assume_role"
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "cluster_fqdn"
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "terraform_code_dir"

echo -e "\n# ------------- Secrets - must be ADDED !!! -------------\n"

echo "### export AWS_ACCESS_KEY_ID='<secrets belongs to AWS_ACCESS_KEY_ID>"
echo "### export AWS_SECRET_ACCESS_KEY='<secrets belongs to AWS_SECRET_ACCESS_KEY>'"
echo "### export TF_VAR_github_token='<GH token to allow TF to create Flux deployment token>'"

echo -e "\n# ------------------------ Code -------------------------"

# Prevent role chaining in case of you already assumed proper role
# This will happen if you run these commands multiple times
cat << \EOF
CURRENT_ASSUME_ROLE_ARN=$( aws sts get-caller-identity --query Arn --output text | sed 's/sts/iam/;s/assumed-role/role/' )
if [[ ! "${CURRENT_ASSUME_ROLE_ARN}" =~ "${AWS_ASSUME_ROLE}" ]]; then
  eval $(aws sts assume-role --role-arn "${AWS_ASSUME_ROLE}" --role-session-name "${USER}@$(hostname -f)-k8s-tf-eks-gitops-$(date +%s)" --duration-seconds 36000 | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)\nexport AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)\nexport AWS_SESSION_TOKEN=\(.SessionToken)\n"')
fi

aws sts get-caller-identity
aws cloudformation deploy \
  --parameter-overrides "ClusterFQDN=${CLUSTER_FQDN}" \
  --stack-name "${CLUSTER_FQDN//./-}-s3-dynamodb-tfstate" --template-file "./cloudformation/s3-dynamodb-tfstate.yaml"

terraform -chdir="${TERRAFORM_CODE_DIR}" init \
  -backend-config="bucket=${CLUSTER_FQDN}" \
  -backend-config="key=terraform-${CLUSTER_FQDN}.tfstate" \
  -backend-config="region=${AWS_DEFAULT_REGION}" \
  -backend-config="dynamodb_table=${CLUSTER_FQDN}"

terraform -chdir="${TERRAFORM_CODE_DIR}" apply \
  -var-file="${PWD}/${CLUSTER_PATH}/../../main-variables.tfvars" \
  -var-file="${PWD}/${CLUSTER_PATH}/../group-variables.tfvars" \
  -var-file="${PWD}/${CLUSTER_PATH}/cluster-variables.tfvars"
EOF
