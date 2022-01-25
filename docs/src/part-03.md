
# Build Amazon EKS clusters using Terraform

Few notes...

## Allow GH Actions to connect to AWS accounts

You also need to allow GitHub Action to connect to the AWS account(s) where you
want to provision the clusters using [Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services).

Example: [AWS federation comes to GitHub Actions](https://awsteele.com/blog/2021/09/15/aws-federation-comes-to-github-actions.html)

```shell
aws cloudformation deploy --region=eu-central-1 --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "GitHubFullRepositoryName=ruzickap/k8s-tf-eks-argocd" \
  --stack-name "ruzickap-k8s-tf-eks-argocd-gh-action-iam-role-oidc" \
  --template-file "./cloudformation/gh-action-iam-role-oidc.yaml" \
  --tags Owner=petr.ruzicka@gmail.com
```

## Run GitHub Actions with Terraform

Run GitHub Actions with Terraform to create Amazon EKS:

```shell
gh workflow run clusters-aws.yml -f clusters=".*(/ruzickap-eks.k8s.use1.dev.proj.aws.mylabs.dev$).*" -f action="apply"
```

or you can create multiple AWS clusters:

```shell
gh workflow run clusters-aws.yml -f clusters=".*(/ruzickap-eks.k8s.use1.dev.proj.aws.mylabs.dev$|/ruzickap-eks2.k8s.use1.dev.proj.aws.mylabs.dev$).*" -f action="apply"
```

You can run Terraform per "group of clusters":

```shell
gh workflow run clusters-aws.yml -f clusters=".*(/dev-sandbox/).*" -f action="apply"
```

Destroy Amazon EKS and related "objects":

```shell
gh workflow run clusters-aws.yml -f clusters=".*(/ruzickap-eks.k8s.use1.dev.proj.aws.mylabs.dev$).*" -f action="destroy"
```
