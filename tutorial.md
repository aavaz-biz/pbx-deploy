# Deploy Aavaz PBX on Google Cloud

## Before you start

This creates **one VM running Aavaz PBX** (Ubuntu 24.04, 4 GB RAM) with a fixed public IP, in its own
network. The firewall opens only what a PBX needs: web (80/443), SSH (22), SIP (UDP 5060) and call
audio (UDP 10000–20000).

Cost is roughly **US$37/month** in Mumbai for the default `e2-medium`. Delete it any time with one
command (last step).

Click **Start** to begin.

## Pick a project

Choose the Google Cloud project to deploy into. It needs billing enabled.

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

Then make it the current project:

```sh
gcloud config set project <walkthrough-project-id/>
```

## Deploy

Pick the zone nearest your phones and SIP provider:

| Zone | Location |
|------|----------|
| `asia-south1-a` | Mumbai (default) |
| `asia-southeast1-a` | Singapore |
| `europe-west3-a` | Frankfurt |
| `us-east1-b` | South Carolina |

Run (change the zone if needed):

```sh
./gcp-deploy.sh --zone asia-south1-a
```

It takes about 1–3 minutes, then prints your PBX's **public IP**.

## Log in

The PBX finishes installing about **3 minutes** after the script ends.

1. Open `https://<public-ip>/`. Your browser will warn about the self-signed certificate; that's expected.
2. Log in as **admin / admin**. You'll be asked to set a new password straight away.
3. Choose **Cloud** as the deployment mode, then **open your current IP for SIP** so your phones can register.

To watch the install:

```sh
gcloud compute ssh aavaz-pbx --zone asia-south1-a --command 'sudo tail -f /var/log/cloud-init-output.log'
```

## Remove it

Deletes the VM, its network, firewall rules and static IP:

```sh
./gcp-deploy.sh --zone asia-south1-a --delete
```

## Done

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

Need help? Email **support@aavaz.biz**.
