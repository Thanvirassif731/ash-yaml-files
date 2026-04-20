# Terraform HCL

## Files Overview
| File Name | Use Case | Target Architecture |
| :--- | :--- | :--- |
| `website-deployment-s3-cloudfront-r53-acm.tf` | This Terraform configuration sets up an S3 bucket for static website hosting, configures Route 53 for DNS and ACM for SSL, and creates a CloudFront distribution with an origin access control. | **AWS S3, CloudFront, Route53, Certificate Manager** |
| `iam-permission.tf` | This configuration sets up IAM user, policy, and access keys for GitHub Actions deployment. | **AWS IAM, GitHub Actions Configuration** |
