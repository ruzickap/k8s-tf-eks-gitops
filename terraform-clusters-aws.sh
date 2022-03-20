#!/usr/bin/env bash

get_variable_from_group_cluster_tfvars () {
  local CLUSTER_PATH="$1" TF_CODE_VARIABLE="$2" VARIABLE_HELPER

  if grep -q "${TF_CODE_VARIABLE}" "${CLUSTER_PATH}/cluster-variables.tfvars" ; then
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
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "cluster_fqdn"
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "terraform_code_dir"

echo -e "\n# ------------- Secrets - must be ADDED !!! -------------\n"

echo "### export AWS_ACCESS_KEY_ID='<secrets belongs to AWS_ACCESS_KEY_ID>"
echo "### export AWS_SECRET_ACCESS_KEY='<secrets belongs to AWS_SECRET_ACCESS_KEY>'"
echo "### export AWS_ROLE_ARN='arn:aws:iam::7xxxxxxxxxx7:role/GitHubOidcFederatedRole'"

echo -e "\n# ------------------------ Code -------------------------"

aws sts assume-role --role-arn "${AWS_ROLE_ARN}" --role-session-name "${USER}@$(hostname -f)-terraform-clusters-aws" --duration-seconds 3600 | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)\nexport AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)\nexport AWS_SESSION_TOKEN=\(.SessionToken)\n"'

cat << \EOF
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
