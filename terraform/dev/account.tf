# ---------------------------------------------------------------------------------------------------------------------
# Create the cluster's KMS key
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_kms_key" "eks-kms_key" {
  description             = "${var.cluster_fqdn} Amazon EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}"
  target_key_id = aws_kms_key.eks-kms_key.key_id
}

# ---------------------------------------------------------------------------------------------------------------------
# Rancher Access
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_user" "rancher" {
  name = "rancher-${var.cluster_fqdn}"
}

resource "aws_iam_user_policy_attachment" "rancher" {
  user       = aws_iam_user.rancher.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_access_key" "rancher" {
  user = aws_iam_user.rancher.name
}

resource "rancher2_cloud_credential" "rancher_aws_account" {
  name        = "aws-${var.aws_account_id}-rancher-${var.cluster_fqdn}"
  description = "Access to AWS account ${var.aws_account_id} for ${var.cluster_fqdn}"
  amazonec2_credential_config {
    access_key = aws_iam_access_key.rancher.id
    secret_key = aws_iam_access_key.rancher.secret
  }
}
