# Aavaz PBX: cloud deploy

One-click deployment of [Aavaz PBX](https://pbx.aavaz.biz) (Free Edition, Docker image
[`aavaz/pbx`](https://hub.docker.com/r/aavaz/pbx)) on AWS and Google Cloud.

Each option creates **one Ubuntu 24.04 VM** with a fixed public IP. The firewall opens only TCP 22
(SSH), 80/443 (web) and UDP 5060 (SIP) plus 10000–20000 (call audio). The PBX installs itself in about
3 minutes.

## Google Cloud

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/open?cloudshell_git_repo=https://github.com/aavaz-biz/pbx-deploy&cloudshell_tutorial=tutorial.md&show=terminal)

The button opens Cloud Shell with a step-by-step guide. Or, from any machine with `gcloud`:

```sh
curl -fsSL https://resources.aavaz.biz/install/gcp-deploy.sh | bash -s -- --project YOUR_PROJECT --zone asia-south1-a
```

## AWS

| Region | |
|---|---|
| Mumbai | [Launch Stack](https://console.aws.amazon.com/cloudformation/home?region=ap-south-1#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| Hyderabad | [Launch Stack](https://console.aws.amazon.com/cloudformation/home?region=ap-south-2#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| Singapore | [Launch Stack](https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-1#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| Frankfurt | [Launch Stack](https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| N. Virginia | [Launch Stack](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |

On the page that opens, pick your **VPC and a public subnet** (an EC2 key pair is optional), then **Create stack**.
Check the region (top right) **before** filling in the form.

## After it's up

1. Open `https://<public-ip>/` (expect a self-signed certificate warning).
2. Log in as **admin / admin** and set a new password.
3. Choose **Cloud** mode and **open your current IP for SIP**.

Pick the region nearest your phones and SIP provider; call quality depends on it.

## Files

| File | Purpose |
|------|---------|
| `aws-cloudformation.yaml` | AWS template (EC2, Elastic IP, security group) |
| `gcp-deploy.sh` | Google Cloud deploy/delete script (`--help`) |
| `cloud-init.yaml` | First-boot setup shared by both; usable as "user data" on any cloud |
| `tutorial.md` | The Cloud Shell walkthrough |

These files are published from Aavaz's internal repository; changes made here will be overwritten.
Questions: **support@aavaz.biz**.
