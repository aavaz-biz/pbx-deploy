# Deploy Aavaz PBX on Google Cloud

## Before you start

This creates **one VM running Aavaz PBX** (Ubuntu 24.04, 4 GB RAM) with a fixed public IP, in its own
network. The firewall opens only what a PBX needs: web (80/443), SSH (22), SIP (UDP 5060) and call
audio (UDP 10000–20000).

Cost is roughly **US$31/month** for the default `e2-medium` in the default region (us-east1); other
regions cost a little more (Mumbai is about US$37). Delete it any time with one command (last step).

Click **Start** to begin.

## Pick a project

Choose the Google Cloud project to deploy into. It needs billing enabled.

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

Then make it the current project:

```sh
gcloud config set project <walkthrough-project-id/>
```

## Pick a region and deploy

Choose the zone **nearest your phones and your SIP provider**. Call quality depends on it. The default
is **us-east1-b**.

| Area | Zone | Location |
|------|------|----------|
| Americas | `us-east1-b` | South Carolina (**default**) |
| | `us-east4-a` | Northern Virginia |
| | `us-central1-a` | Iowa |
| | `us-west1-a` | Oregon |
| | `northamerica-northeast1-a` | Montréal |
| | `southamerica-east1-a` | São Paulo |
| Europe | `europe-west2-a` | London |
| | `europe-west1-b` | Belgium |
| | `europe-west3-a` | Frankfurt |
| Middle East | `me-central1-a` | Doha |
| Asia Pacific | `asia-south1-a` | Mumbai |
| | `asia-south2-a` | Delhi |
| | `asia-southeast1-a` | Singapore |
| | `asia-northeast1-a` | Tokyo |
| | `australia-southeast1-a` | Sydney |

Any other zone works too (`gcloud compute zones list`).

Deploy in the default zone:

```sh
./gcp-deploy.sh
```

Or in another zone, by changing the zone name:

```sh
./gcp-deploy.sh --zone asia-south1-a
```

It takes about 1–3 minutes, then prints your PBX's **public IP**.

## Log in

The PBX finishes installing about **3 minutes** after the script ends.

1. Open `https://<public-ip>/`. Your browser will warn about the self-signed certificate; that's expected.
2. Log in as **admin / admin**. You'll be asked to set a new password straight away.
3. Choose **Cloud** as the deployment mode, then **open your current IP for SIP** so your phones can register.

To watch the install (use your zone):

```sh
gcloud compute ssh aavaz-pbx --zone us-east1-b --command 'sudo tail -f /var/log/cloud-init-output.log'
```

## Remove it

Deletes the VM, its network, firewall rules and static IP (use the same zone you deployed in):

```sh
./gcp-deploy.sh --zone us-east1-b --delete
```

## Done

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

Need help? Email **support@aavaz.biz**.
