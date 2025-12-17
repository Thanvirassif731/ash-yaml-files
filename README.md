# 🚀 GitHub Actions CI/CD Templates for AWS

Welcome to this collection of production-ready GitHub Actions workflows. This repository contains "plug-and-play" YAML configurations to automate deployments to **AWS EC2** (for MERN/Node.js apps) and **AWS S3** (for static websites).

## 📂 Repository Contents

| File Name | Use Case | Target Architecture |
| :--- | :--- | :--- |
| `ec2-deploy.yml` | Full Stack Applications | **AWS EC2** (Ubuntu + Nginx + PM2) |
| `s3-deploy.yml` | Static Websites | **AWS S3** (HTML/CSS/JS) |

---

## 🛠️ Option 1: AWS EC2 Deployment (MERN Stack)

Use this workflow if you have a full-stack application (e.g., React Frontend + Node/Express Backend) running on a Virtual Machine (EC2).

### Prerequisites
* An AWS EC2 instance (Ubuntu recommended).
* **Nginx** configured as a reverse proxy.
* **PM2** installed to manage the backend process.
* **Git** installed on the server.

### Required GitHub Secrets
To use this, go to **Settings** > **Secrets and variables** > **Actions** and add:

| Secret Name | Description | Example |
| :--- | :--- | :--- |
| `EC2_HOST` | Public IP address of your instance | `54.211.10.22` |
| `EC2_USER` | SSH Username | `ubuntu` |
| `EC2_SSH_KEY` | Your private key content (PEM file) | `-----BEGIN RSA PRIVATE KEY...` |

### How it Works
1.  SSH's into your server.
2.  Pulls the latest code from the `main` branch.
3.  Installs dependencies for both `backend/` and `frontend/`.
4.  Restarts the backend API using `pm2`.
5.  Rebuilds the React frontend and reloads Nginx.

---

## ☁️ Option 2: AWS S3 Deployment (Static Site)

Use this workflow if you have a simple static website (HTML, CSS, JS) that does not require a backend server.

### Prerequisites
* An AWS S3 Bucket configured for "Static Website Hosting".
* An IAM User with `AmazonS3FullAccess` (or specific bucket access).

### Required GitHub Secrets
To use this, go to **Settings** > **Secrets and variables** > **Actions** and add:

| Secret Name | Description |
| :--- | :--- |
| `AWS_S3_BUCKET` | The name of your bucket (e.g., `my-portfolio-2025`) |
| `AWS_ACCESS_KEY_ID` | Your IAM User Access Key |
| `AWS_SECRET_ACCESS_KEY` | Your IAM User Secret Key |
| `AWS_REGION` | The region of your bucket (e.g., `us-east-1`) |

### How it Works
1.  Checks out your code.
2.  Configures AWS credentials securely.
3.  Uses `aws s3 sync` to upload only changed files.
4.  Automatically deletes files in the bucket that you removed from the repo (keeping it clean).

---

## ⚡ Quick Start Guide

1.  **Choose your workflow:** Decide if you are deploying to EC2 or S3.
2.  **Create the file:** inside your own project, create the folder path:
    `.github/workflows/deploy.yml`
3.  **Copy the code:** Copy the content of the relevant YAML file from this repo into that file.
4.  **Set Secrets:** Add the secrets listed above to your repository settings.
5.  **Push:** Commit and push to `main` to trigger your first automatic deployment!

---

## ⚠️ Common Troubleshooting

* **EC2 Permission Denied:** Ensure your `EC2_SSH_KEY` secret includes the `-----BEGIN...` and `-----END...` lines.
* **S3 Access Denied:** Check if your IAM user has the correct `s3:PutObject` and `s3:ListBucket` permissions.
* **Workflow not triggering:** Ensure your branch name in the YAML file (`branches: [ "main" ]`) matches your actual default branch (sometimes it is called `master`).

---

**Maintained by [Thanvir Assif]**
*Happy Coding & Automating!* 🤖
