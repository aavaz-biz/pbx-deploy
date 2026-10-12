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
curl -fsSL https://resources.aavaz.biz/install/gcp-deploy.sh | bash -s -- --project YOUR_PROJECT --zone us-east1-b
```

## AWS

| Region | Code | Launch |
|---|---|---|
| N. Virginia (default) | `us-east-1` | [![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| Ohio | `us-east-2` | [![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| Oregon | `us-west-2` | [![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| Canada (Central) | `ca-central-1` | [![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ca-central-1#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| Sao Paulo | `sa-east-1` | [![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=sa-east-1#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| Ireland | `eu-west-1` | [![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=eu-west-1#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| London | `eu-west-2` | [![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=eu-west-2#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| Frankfurt | `eu-central-1` | [![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| Mumbai | `ap-south-1` | [![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ap-south-1#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| Singapore | `ap-southeast-1` | [![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-1#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| Tokyo | `ap-northeast-1` | [![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ap-northeast-1#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |
| Sydney | `ap-southeast-2` | [![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-2#/stacks/create/review?templateURL=https://aavaz-pbx-install.s3.amazonaws.com/install/aws-cloudformation.yaml&stackName=aavaz-pbx) |

On the page that opens, leave the defaults (an EC2 key pair is optional) and click
**Create stack**. The stack creates its own small network, so there is no VPC or subnet to pick.
Check the region (top right) **before** filling in the form.

## After it's up

1. Open `https://<public-ip>/` (expect a self-signed certificate warning).
2. Log in as **admin / admin** and set a new password.
3. Choose **Cloud** mode and **open your current IP for SIP**.

Pick the region nearest your phones and SIP provider; call quality depends on it. The default is
**us-east-1** on AWS and **us-east1** (zone `us-east1-b`) on Google Cloud; `./gcp-deploy.sh --help`
lists suggested zones worldwide.

## Files

| File | Purpose |
|------|---------|
| `aws-cloudformation.yaml` | AWS template (EC2, Elastic IP, security group) |
| `gcp-deploy.sh` | Google Cloud deploy/delete script (`--help`) |
| `cloud-init.yaml` | First-boot setup shared by both; usable as "user data" on any cloud |
| `tutorial.md` | The Cloud Shell walkthrough |

These files are published from Aavaz's internal repository; changes made here will be overwritten.
Questions: **support@aavaz.biz**.
