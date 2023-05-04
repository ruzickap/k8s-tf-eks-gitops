# Create initial AWS structure

<!-- toc -->

## Requirements

If you would like to follow this documents you will need to do few configuration
steps:

* Allow GitHub runners to access the AWS accounts

## Prepare the local working environment

<aside class="note">

<h1>Note</h1>

You can skip these steps if you have all the required software already
installed.

</aside>

Install necessary software:

```bash
if command -v apt-get &> /dev/null; then
  sudo apt update -qq
  sudo apt-get install -y -qq curl git jq sudo unzip > /dev/null
fi
```

Install [AWS CLI](https://aws.amazon.com/cli/) binary:

```bash
if ! command -v aws &> /dev/null; then
  # renovate: datasource=github-tags depName=aws/aws-cli
  AWSCLI_VERSION="2.11.17"
  curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" -o "/tmp/awscli.zip"
  unzip -q -o /tmp/awscli.zip -d /tmp/
  sudo /tmp/aws/install
fi
```

Install [kubectl](https://github.com/kubernetes/kubectl) binary:

```bash
if ! command -v kubectl &> /dev/null; then
  # renovate: datasource=github-tags depName=kubernetes/kubectl extractVersion=^kubernetes-(?<version>.+)$
  KUBECTL_VERSION="1.26.3"
  sudo curl -s -Lo /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/$(uname | sed "s/./\L&/g")/amd64/kubectl"
  sudo chmod a+x /usr/local/bin/kubectl
fi
```

Install [Helm](https://helm.sh/):

```bash
if ! command -v helm &> /dev/null; then
  # renovate: datasource=github-tags depName=helm/helm
  HELM_VERSION="3.11.3"
  curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash -s -- --version "v${HELM_VERSION}"
fi
```

Install [kustomize](https://kustomize.io/):

```bash
if ! command -v kustomize &> /dev/null; then
  # renovate: datasource=github-tags depName=kubernetes-sigs/kustomize extractVersion=^kustomize\/v(?<version>.+)$
  KUSTOMIZE_VERSION="5.0.1"
  curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | sudo bash -s "${KUSTOMIZE_VERSION}" /usr/local/bin/
fi
```

Install [flux](https://fluxcd.io/):

```bash
if ! command -v flux &> /dev/null; then
  # shellcheck disable=SC2034
  # renovate: datasource=github-tags depName=fluxcd/flux2
  FLUX_VERSION="0.40.2"
  curl -s https://fluxcd.io/install.sh | sudo -E bash
fi
```

## Create KMS key for SOPS

> This should be done only once.

Create KMS key which will be used to encrypt/decrypt the secrets stored in git
repository used by Flux.

```bash
aws cloudformation deploy --region=eu-central-1 \
  --stack-name "kms-key-sops" --template-file "./cloudformation/kms-key-sops.yaml"
```

This key should not be deleted otherwise you need to re-encrypt all secrets in
git repository.

## Configure AWS Route 53 Domain delegation

> This should be done only once.

Create DNS zone for EKS clusters:

```shell
export BASE_DOMAIN="k8s.use1.dev.proj.aws.mylabs.dev"
export CLOUDFLARE_EMAIL="petr.ruzicka@gmail.com"
export CLOUDFLARE_API_KEY="11234567890"

aws route53 create-hosted-zone --output json \
  --name "${BASE_DOMAIN}" \
  --caller-reference "$(date)" \
  --hosted-zone-config="{\"Comment\": \"Created by petr.ruzicka@gmail.com\", \"PrivateZone\": false}" | jq
```

Use your domain registrar to change the nameservers for your zone (for example
`mylabs.dev`) to use the Amazon Route 53 nameservers. Here is the way how you
can find out the the Route 53 nameservers:

```shell
NEW_ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name==\`${BASE_DOMAIN}.\`].Id" --output text)
NEW_ZONE_NS=$(aws route53 get-hosted-zone --output json --id "${NEW_ZONE_ID}" --query "DelegationSet.NameServers")
NEW_ZONE_NS1=$(echo "${NEW_ZONE_NS}" | jq -r ".[0]")
NEW_ZONE_NS2=$(echo "${NEW_ZONE_NS}" | jq -r ".[1]")
```

Create the NS record in `k8s.use1.dev.proj.aws.mylabs.dev` (`BASE_DOMAIN`) for
proper zone delegation. This step depends on your domain registrar - I'm using
CloudFlare and using Ansible to automate it:

```shell
ansible -m cloudflare_dns -c local -i "localhost," localhost -a "zone=mylabs.dev record=${BASE_DOMAIN} type=NS value=${NEW_ZONE_NS1} solo=true proxied=no account_email=${CLOUDFLARE_EMAIL} account_api_token=${CLOUDFLARE_API_KEY}"
ansible -m cloudflare_dns -c local -i "localhost," localhost -a "zone=mylabs.dev record=${BASE_DOMAIN} type=NS value=${NEW_ZONE_NS2} solo=false proxied=no account_email=${CLOUDFLARE_EMAIL} account_api_token=${CLOUDFLARE_API_KEY}"
```

Output:

```text
localhost | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": true,
    "result": {
        "record": {
            "content": "ns-885.awsdns-46.net",
            "created_on": "2020-11-13T06:25:32.18642Z",
            "id": "dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxb",
            "locked": false,
            "meta": {
                "auto_added": false,
                "managed_by_apps": false,
                "managed_by_argo_tunnel": false,
                "source": "primary"
            },
            "modified_on": "2020-11-13T06:25:32.18642Z",
            "name": "k8s.mylabs.dev",
            "proxiable": false,
            "proxied": false,
            "ttl": 1,
            "type": "NS",
            "zone_id": "2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxe",
            "zone_name": "mylabs.dev"
        }
    }
}
localhost | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": true,
    "result": {
        "record": {
            "content": "ns-1692.awsdns-19.co.uk",
            "created_on": "2020-11-13T06:25:37.605605Z",
            "id": "9xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxb",
            "locked": false,
            "meta": {
                "auto_added": false,
                "managed_by_apps": false,
                "managed_by_argo_tunnel": false,
                "source": "primary"
            },
            "modified_on": "2020-11-13T06:25:37.605605Z",
            "name": "k8s.mylabs.dev",
            "proxiable": false,
            "proxied": false,
            "ttl": 1,
            "type": "NS",
            "zone_id": "2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxe",
            "zone_name": "mylabs.dev"
        }
    }
}
```

## Allow GH Actions to connect to AWS accounts

You also need to allow GitHub Action to connect to the AWS account(s) where you
want to provision the clusters.

Example: [AWS federation comes to GitHub Actions](https://awsteele.com/blog/2021/09/15/aws-federation-comes-to-github-actions.html)

```shell
aws cloudformation deploy --region=eu-central-1 --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "GitHubFullRepositoryName=ruzickap/k8s-tf-eks-gitops" \
  --stack-name "${USER}-k8s-tf-eks-gitops-gh-action-iam-role-oidc" \
  --template-file "./cloudformation/gh-action-iam-role-oidc.yaml" \
  --tags "Owner=petr.ruzicka@gmail.com"
```

## Run GitHub Actions with Terraform

Run GitHub Actions with Terraform to create Amazon EKS:

```bash
gh workflow run clusters-aws.yml -f clusters=".*(/ruzickap01.k8s.use1.dev.proj.aws.mylabs.dev$).*" -f action="apply"
gh workflow run clusters-aws.yml -f clusters=".*(/mgmt01.k8s.use1.dev.proj.aws.mylabs.dev$).*" -f action="apply"
```

or you can create multiple AWS clusters:

```bash
gh workflow run clusters-aws.yml -f clusters=".*(/ruzickap.*.k8s.use1.dev.proj.aws.mylabs.dev$|/mgmt01.k8s.use1.dev.proj.aws.mylabs.dev$).*" -f action="apply"
```

You can run Terraform per "group of clusters":

```bash
gh workflow run clusters-aws.yml -f clusters=".*/aws-dev-sandbox/.*" -f action="apply"
gh workflow run clusters-aws.yml -f clusters=".*" -f action="apply"
```

Destroy Amazon EKS and related "objects":

```bash
gh workflow run clusters-aws.yml -f clusters=".*(/ruzickap01.k8s.use1.dev.proj.aws.mylabs.dev$).*" -f action="destroy"
gh workflow run clusters-aws.yml -f clusters=".*ruzickap01.k8s.use1.dev.proj.aws.mylabs.dev.*" -f action="destroy"
gh workflow run clusters-aws.yml -f clusters=".*" -f action="destroy"
```

## ArgoCD

* [App of Apps Best Practices](https://medium.com/dzerolabs/turbocharge-argocd-with-app-of-apps-pattern-and-kustomized-helm-ea4993190e7c)

## Flux

```bash
flux get all --all-namespaces
flux tree kustomization flux-system
flux logs
```

### Edit secrets by SOPS

Encrypt `^(data|stringData)$` field in file:

```bash
sops --encrypt --in-place clusters/aws-dev-mgmt/mgmt01.k8s.use1.dev.proj.aws.mylabs.dev/flux/cluster-apps-secrets.yaml
```

Edit encrypted file:

```bash
sops cluster-apps-group-secrets.yaml
```
