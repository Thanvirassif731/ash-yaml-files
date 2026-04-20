# --- 1. AWS Provider Configuration --- Provider is already defined in main.tf, so we don't need to repeat it here. Just make sure to run `terraform init` in the root directory to set everything up before applying this IAM configuration.
# --- 2. Create the IAM User ---
# This is the "Identity" that GitHub Actions will use to log in.
resource "aws_iam_user" "github_actions" {
  name = "github-actions-auto-cloud-deploy"
  tags = {
    Project = "AutoCloudDeploy"
    Owner   = "Ash"
  }
}


# --- 3. Define the Least Privilege Policy ---
# We are only giving GitHub permission to touch what it absolutely needs.
resource "aws_iam_policy" "deploy_policy" {
  name        = "GitHubActionsDeployPolicy"
  description = "Allows S3 sync and CloudFront invalidation for the test subdomain"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permission: Manage files in the specific S3 bucket
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "${aws_s3_bucket.website_bucket.arn}",
          "${aws_s3_bucket.website_bucket.arn}/*"
        ]
      },
      {
        # Permission: Tell CloudFront to refresh its cache
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = [
          "${aws_cloudfront_distribution.distro.arn}"
        ]
      }
    ]
  })
}


# --- 4. Attach Policy to User ---
# This links the "locked door" (the policy) to the "key holder" (the user).
resource "aws_iam_user_policy_attachment" "attach_deploy" {
  user       = aws_iam_user.github_actions.name
  policy_arn = aws_iam_policy.deploy_policy.arn
}


# --- 5. Create Access Keys ---
# This generates the credentials you will paste into GitHub Secrets.
resource "aws_iam_access_key" "github_keys" {
  user = aws_iam_user.github_actions.name
}


# --- 6. Outputs (The "The Goods") ---
# These are sensitive. Terraform won't show them unless you specifically ask.
output "github_actions_access_key" {
  value     = aws_iam_access_key.github_keys.id
  sensitive = true
}

output "github_actions_secret_key" {
  value     = aws_iam_access_key.github_keys.secret
  sensitive = true
}
