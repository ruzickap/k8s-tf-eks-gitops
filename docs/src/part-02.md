# Create Amazon EKS cluster with Rancher (master cluster)

This cluster will be used as "master cluster" which will provision all other
K8s clusters.

Initial variables needed for "Master cluster"

```bash
export AWS_DEFAULT_REGION="eu-central-1"
export BASE_DOMAIN="k8s.mylabs.dev"
export CLUSTER_NAME="main-eks"
export CLUSTER_FQDN="${CLUSTER_NAME}.${BASE_DOMAIN}"
export ENVIRONMENT="dev"
export MY_EMAIL="petr.ruzicka@gmail.com"
export TAGS="Owner=${MY_EMAIL} Environment=${ENVIRONMENT} Group=Cloud_Native Squad=Container_Platform"
# * "production" - valid certificates signed by Lets Encrypt ""
# * "staging" - not trusted certs signed by Lets Encrypt "Fake LE Intermediate X1"
export LETSENCRYPT_ENVIRONMENT="staging"
export KUBECONFIG="${PWD}/tmp/kubeconfig-${CLUSTER_NAME}.conf"
```

Credentials / Secrets:

```shell
export AWS_ACCESS_KEY_ID="xxxxxxxxxxxxxxxxxx"
export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export MY_PASSWORD="xxxx"
```

Create temporary directory for files used for creating/configuring EKS Cluster
and it's components:

```bash
mkdir -p "tmp"
```

## Create Route53

Create CloudFormation template containing for Route53

Put new domain `CLUSTER_FQDN` to the Route 53 and configure the DNS delegation
from the `BASE_DOMAIN`.

Create Route53 zone:

```bash
if [[ $(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --query "StackSummaries[?starts_with(StackName, \`${CLUSTER_NAME}-route53\`) == \`true\`].StackName" --output text) == "" ]]; then
  # shellcheck disable=SC2001
  eval aws cloudformation "create-stack" \
    --parameters "ParameterKey=BaseDomain,ParameterValue=${BASE_DOMAIN} ParameterKey=ClusterFQDN,ParameterValue=${CLUSTER_FQDN}" \
    --stack-name "${CLUSTER_NAME}-route53" \
    --template-body "file://cloudformation/master-cluster-route53.yaml" \
    --tags "$(echo "${TAGS}" | sed  -e 's/\([^ =]*\)=\([^ ]*\)/Key=\1,Value=\2/g')" || true
fi
```

## Create Amazon EKS

Create [Amazon EKS](https://aws.amazon.com/eks/) in AWS by using [eksctl](https://eksctl.io/).

![eksctl](https://raw.githubusercontent.com/weaveworks/eksctl/c365149fc1a0b8d357139cbd6cda5aee8841c16c/logo/eksctl.png
"eksctl")

Create the Amazon EKS cluster using `eksctl`:

```bash
cat > "tmp/${CLUSTER_FQDN}-eksctl.yaml" << EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: ${CLUSTER_NAME}
  region: ${AWS_DEFAULT_REGION}
  version: "1.21"
  tags: &tags
$(echo "${TAGS}" | sed "s/ /\\n    /g; s/^/    /g; s/=/: /g")
iam:
  withOIDC: true
  serviceAccounts:
    - metadata:
        name: cert-manager
        namespace: cert-manager
      wellKnownPolicies:
        certManager: true
    - metadata:
        name: external-dns
        namespace: external-dns
      wellKnownPolicies:
        externalDNS: true

managedNodeGroups:
  - name: managed-ng-1
    amiFamily: Bottlerocket
    instanceType: t3.large
    desiredCapacity: 2
    minSize: 2
    maxSize: 3
    volumeSize: 30
    volumeType: gp3
    tags:
      <<: *tags
      compliance:na:defender: bottlerocket
    volumeEncrypted: true
    disableIMDSv1: true
EOF

if [[ ! -s "${KUBECONFIG}" ]] ; then
  if  ! eksctl get clusters --name="${CLUSTER_NAME}" &> /dev/null ; then
    eksctl create cluster --config-file "tmp/${CLUSTER_FQDN}-eksctl.yaml" --kubeconfig "${KUBECONFIG}"
  else
    eksctl utils write-kubeconfig --cluster="${CLUSTER_NAME}" --kubeconfig "${KUBECONFIG}"
  fi
fi
```

Add add the user or role to the `aws-auth` ConfigMap. This is handy if you are
using different user for CLI operations and different user/role for accessing
the AWS Console to see EKS Workloads in Cluster's tab.

```bash
if [[ -n ${AWS_CONSOLE_ADMIN_ROLE_ARN_MAIN_EKS+x} ]] && ! eksctl get iamidentitymapping --cluster="${CLUSTER_NAME}" --arn="${AWS_CONSOLE_ADMIN_ROLE_ARN_MAIN_EKS}" &> /dev/null ; then
  eksctl create iamidentitymapping --cluster="${CLUSTER_NAME}" --arn="${AWS_CONSOLE_ADMIN_ROLE_ARN_MAIN_EKS}" --group system:masters --username admin
fi

if [[ -n ${AWS_USER_ROLE_ARN_MAIN_EKS+x} ]] && ! eksctl get iamidentitymapping --cluster="${CLUSTER_NAME}" --arn="${AWS_USER_ROLE_ARN_MAIN_EKS}" &> /dev/null ; then
  eksctl create iamidentitymapping --cluster="${CLUSTER_NAME}" --arn="${AWS_USER_ROLE_ARN_MAIN_EKS}" --group system:masters --username admin
fi
```

## Post installation tasks

Change TTL=60 of SOA + NS records for new domain
(it can not be done in CloudFormation):

```bash
if [[ ! -s "tmp/${CLUSTER_FQDN}-route53-hostedzone-ttl.yml" ]]; then
  HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name==\`${CLUSTER_FQDN}.\`].Id" --output text)
  RESOURCE_RECORD_SET_SOA=$(aws route53 --output json list-resource-record-sets --hosted-zone-id "${HOSTED_ZONE_ID}" --query "(ResourceRecordSets[?Type == \`SOA\`])[0]" | sed "s/\"TTL\":.*/\"TTL\": 60,/")
  RESOURCE_RECORD_SET_NS=$(aws route53 --output json list-resource-record-sets --hosted-zone-id "${HOSTED_ZONE_ID}" --query "(ResourceRecordSets[?Type == \`NS\`])[0]" | sed "s/\"TTL\":.*/\"TTL\": 60,/")
  cat << EOF | jq > "tmp/${CLUSTER_FQDN}-route53-hostedzone-ttl.yml"
{
    "Comment": "Update record to reflect new TTL for SOA and NS records",
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet":
${RESOURCE_RECORD_SET_SOA}
        },
        {
            "Action": "UPSERT",
            "ResourceRecordSet":
${RESOURCE_RECORD_SET_NS}
        }
    ]
}
EOF
  aws route53 change-resource-record-sets --output json --hosted-zone-id "${HOSTED_ZONE_ID}" --change-batch="file://tmp/${CLUSTER_FQDN}-route53-hostedzone-ttl.yml"
fi
```

## DNS, Ingress, Certificates

Install the basic tools, before running some applications like DNS integration
([external-dns](https://github.com/kubernetes-sigs/external-dns)), Ingress ([ingress-nginx](https://kubernetes.github.io/ingress-nginx/)),
and certificate management ([cert-manager](https://cert-manager.io/)).

### cert-manager

Install `cert-manager`
[helm chart](https://artifacthub.io/packages/helm/jetstack/cert-manager)
and modify the
[default values](https://github.com/jetstack/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml).
Service account `external-dns` was created by `eksctl`.

```bash
helm repo add --force-update jetstack https://charts.jetstack.io
helm upgrade --install --version v1.7.0 --namespace cert-manager --create-namespace --wait --values - cert-manager jetstack/cert-manager << EOF
installCRDs: true
serviceAccount:
  create: false
  name: cert-manager
extraArgs:
  - --enable-certificate-owner-ref=true
EOF
```

Add ClusterIssuers for Let's Encrypt staging and production:

```bash
kubectl apply -f - << EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging-dns
  namespace: cert-manager
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: ${MY_EMAIL}
    privateKeySecretRef:
      name: letsencrypt-staging-dns
    solvers:
      - selector:
          dnsZones:
            - ${CLUSTER_FQDN}
        dns01:
          route53:
            region: ${AWS_DEFAULT_REGION}
---
# Create ClusterIssuer for production to get real signed certificates
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production-dns
  namespace: cert-manager
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${MY_EMAIL}
    privateKeySecretRef:
      name: letsencrypt-production-dns
    solvers:
      - selector:
          dnsZones:
            - ${CLUSTER_FQDN}
        dns01:
          route53:
            region: ${AWS_DEFAULT_REGION}
EOF

kubectl wait --namespace cert-manager --timeout=10m --for=condition=Ready clusterissuer --all
```

### external-dns

Install `external-dns`
[helm chart](https://artifacthub.io/packages/helm/bitnami/external-dns)
and modify the
[default values](https://github.com/bitnami/charts/blob/master/bitnami/external-dns/values.yaml).
`external-dns` will take care about DNS records.
Service account `external-dns` was created by `eksctl`.

```bash
helm repo add --force-update bitnami https://charts.bitnami.com/bitnami
helm upgrade --install --version 6.1.1 --namespace external-dns --wait --values - external-dns bitnami/external-dns << EOF
aws:
  region: ${AWS_DEFAULT_REGION}
domainFilters:
  - ${CLUSTER_FQDN}
interval: 20s
policy: sync
serviceAccount:
  create: false
  name: external-dns
EOF
```

### ingress-nginx

Install `ingress-nginx`
[helm chart](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx)
and modify the
[default values](https://github.com/kubernetes/ingress-nginx/blob/master/charts/ingress-nginx/values.yaml).

```bash
helm repo add --force-update ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade --install --version 4.0.16 --namespace ingress-nginx --create-namespace --wait --values - ingress-nginx ingress-nginx/ingress-nginx << EOF
controller:
  replicaCount: 2
  watchIngressWithoutClass: true
  service:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
      service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: "$(echo "${TAGS}" | tr " " ,)"
EOF
```

### Rancher

Create Let's Encrypt certificate (using Route53):

```bash
kubectl get namespace cattle-system &> /dev/null || kubectl create namespace cattle-system

kubectl apply -f - << EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ingress-cert-${LETSENCRYPT_ENVIRONMENT}
  namespace: cattle-system
spec:
  secretName: ingress-cert-${LETSENCRYPT_ENVIRONMENT}
  issuerRef:
    name: letsencrypt-${LETSENCRYPT_ENVIRONMENT}-dns
    kind: ClusterIssuer
  commonName: "rancher.${CLUSTER_FQDN}"
  dnsNames:
    - "rancher.${CLUSTER_FQDN}"
EOF

kubectl wait --namespace cattle-system --for=condition=Ready --timeout=20m certificate "ingress-cert-${LETSENCRYPT_ENVIRONMENT}"
```

Install `rancher-server`
[helm chart](https://github.com/rancher/rancher/tree/master/chart)
and modify the
[default values](https://github.com/rancher/rancher/blob/master/chart/values.yaml).

```bash
helm repo add --force-update rancher-latest https://releases.rancher.com/server-charts/latest
helm upgrade --install --version 2.6.3 --namespace cattle-system --wait --values - rancher rancher-latest/rancher << EOF
hostname: rancher.${CLUSTER_FQDN}
ingress:
  tls:
    source: secret
    secretName: ingress-cert-${LETSENCRYPT_ENVIRONMENT}
replicas: 2
bootstrapPassword: "${MY_PASSWORD}"
EOF

kubectl wait --namespace cattle-system --for condition=available deployment rancher
```

Notes: [Unable to create API keys for an user using curl](https://forums.rancher.com/t/unable-to-create-api-keys-for-an-user-using-curl/12899/3)

Create the API token:

```bash
set +x
LOGIN_TOKEN=$( curl -k -s "https://rancher.${CLUSTER_FQDN}/v3-public/localProviders/local?action=login" -H 'content-type: application/json' --data-binary "{\"username\":\"admin\",\"password\":\"${MY_PASSWORD}\"}" | jq -r .token )
curl -k -s "https://rancher.${CLUSTER_FQDN}/v3/cloudcredentials" -H 'Content-Type: application/json' -H "Authorization: Bearer ${LOGIN_TOKEN}" --data-binary "{\"type\":\"provisioning.cattle.io/cloud-credential\",\"metadata\":{\"generateName\":\"cc-\",\"namespace\":\"fleet-default\"},\"_name\":\"aws-credentials-${AWS_ACCOUNT_ID_ORG1}\",\"annotations\":{\"provisioning.cattle.io/driver\":\"aws\",\"field.cattle.io/description\":\"aws-credentials-${AWS_ACCOUNT_ID_ORG1}\"},\"amazonec2credentialConfig\":{\"defaultRegion\":\"${AWS_DEFAULT_REGION}\",\"accessKey\":\"${AWS_ACCESS_KEY_ID_ORG1}\",\"secretKey\":\"${AWS_SECRET_ACCESS_KEY_ORG1}\"},\"_type\":\"provisioning.cattle.io/cloud-credential\",\"name\":\"aws-credentials-${AWS_ACCOUNT_ID_ORG1}\"}" > /dev/null
```
