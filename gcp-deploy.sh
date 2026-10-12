#!/bin/bash
#
# Description: Deploy (or delete) Aavaz PBX on Google Cloud: one Ubuntu 24.04
#   VM with a static IP, in its own VPC network whose firewall exposes only
#   SSH, HTTP/HTTPS, SIP and RTP. The VM boots with cloud-init.yaml (same file
#   as AWS), which runs the hosted installer and sets the NAT address.
#   Runs in Cloud Shell or anywhere gcloud is logged in.
# Usage:
#   gcp-deploy.sh [--project ID] [--zone asia-south1-a] [--name aavaz-pbx]
#                 [--machine-type e2-medium] [--disk-size 30] [--ssh-cidr CIDR]
#   gcp-deploy.sh [--project ID] [--zone Z] [--name N] --delete
#   curl -fsSL https://resources.aavaz.biz/install/gcp-deploy.sh | bash -s -- [options]
# --project defaults to gcloud's current project (the one selected in Cloud
# Shell). cloud-init.yaml is read from beside this script, else downloaded.
#
# Exposure contract (same as AWS): TCP 22, 80, 443 + UDP 5060 (SIP),
# 10000-20000 (RTP). Nothing else. SIP is open to all at this firewall; the
# PBX's own iptables allow-list restricts it to IPs opened in the app.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" && pwd)"

readonly CLOUD_INIT_URL="https://resources.aavaz.biz/install/cloud-init.yaml"
readonly IMAGE_FAMILY="ubuntu-2404-lts-amd64"
readonly IMAGE_PROJECT="ubuntu-os-cloud"
readonly SUBNET_RANGE="10.80.0.0/24"
readonly RTP_RANGE="10000-20000"          # must match etc-ast/rtp.conf
readonly IAP_RANGE="35.235.240.0/20"      # console "SSH" button (IAP)

PROJECT=""
ZONE="asia-south1-a"
NAME="aavaz-pbx"
MACHINE_TYPE="e2-medium"
DISK_SIZE_GB=30
SSH_CIDR="0.0.0.0/0"
CLOUD_INIT="${SCRIPT_DIR}/cloud-init.yaml"
DELETE=0

function usage() {
  cat <<'EOF'
Deploy (or delete) Aavaz PBX on Google Cloud: an Ubuntu 24.04 VM with a static IP
in its own network; firewall opens only TCP 22/80/443, UDP 5060 and 10000-20000.

Usage:
  gcp-deploy.sh [--project ID] [--zone asia-south1-a] [--name aavaz-pbx]
                [--machine-type e2-medium] [--disk-size 30] [--ssh-cidr CIDR]
  gcp-deploy.sh [--project ID] [--zone Z] [--name N] --delete

--project defaults to gcloud's current project (the one selected in Cloud Shell).
Pick the zone nearest your phones and SIP provider, e.g. asia-south1-a (Mumbai),
asia-southeast1-a (Singapore), europe-west3-a (Frankfurt), us-east1-b (S. Carolina).
EOF
}

function die() {
  echo "ERROR: $*" >&2
  exit 1
}

function log() {
  echo "==> $*"
}

function parse_args() {
  while (( $# )); do
    case "$1" in
      --project) PROJECT="$2"; shift ;;
      --zone) ZONE="$2"; shift ;;
      --name) NAME="$2"; shift ;;
      --machine-type) MACHINE_TYPE="$2"; shift ;;
      --disk-size) DISK_SIZE_GB="$2"; shift ;;
      --ssh-cidr) SSH_CIDR="$2"; shift ;;
      --cloud-init) CLOUD_INIT="$2"; shift ;;
      --delete) DELETE=1 ;;
      -h|--help) usage; exit 0 ;;
      *) usage; die "unknown option: $1" ;;
    esac
    shift
  done
  if [[ -z "${PROJECT}" ]]; then
    PROJECT="$(gcloud config get-value project 2>/dev/null || true)"
    [[ -n "${PROJECT}" ]] || { usage; die "no project: pass --project, or select one in Cloud Shell"; }
    log "using current gcloud project: ${PROJECT}"
  fi
  REGION="${ZONE%-*}"
  NETWORK="${NAME}-net"
  SUBNET="${NAME}-subnet"
  ADDRESS="${NAME}-ip"
  TAG="${NAME}"
  readonly PROJECT ZONE NAME MACHINE_TYPE DISK_SIZE_GB SSH_CIDR CLOUD_INIT DELETE
  readonly REGION NETWORK SUBNET ADDRESS TAG
}

# gcloud with the project pinned, quiet prompts.
function gc() {
  gcloud --project "${PROJECT}" --quiet "$@"
}

function create_firewall_rule() {
  local rule="$1" allow="$2" sources="$3"
  if gc compute firewall-rules describe "${rule}" >/dev/null 2>&1; then
    log "firewall rule ${rule} exists"
    return
  fi
  gc compute firewall-rules create "${rule}" --network "${NETWORK}" \
    --direction INGRESS --allow "${allow}" --source-ranges "${sources}" \
    --target-tags "${TAG}" >/dev/null
  log "firewall rule ${rule}: ${allow} from ${sources}"
}

function deploy() {
  local cloud_init="${CLOUD_INIT}"
  if [[ ! -r "${cloud_init}" ]]; then
    cloud_init="$(mktemp)"
    curl -fsSL --retry 3 "${CLOUD_INIT_URL}" -o "${cloud_init}" \
      || die "cloud-init not found beside the script and download failed: ${CLOUD_INIT_URL}"
    log "cloud-init downloaded from ${CLOUD_INIT_URL}"
  fi
  head -n 1 "${cloud_init}" | grep -q '^#cloud-config' || die "not a cloud-config file: ${cloud_init}"

  log "enabling Compute Engine API (first time can take a minute)"
  gc services enable compute.googleapis.com

  if gc compute networks describe "${NETWORK}" >/dev/null 2>&1; then
    log "network ${NETWORK} exists"
  else
    gc compute networks create "${NETWORK}" --subnet-mode custom >/dev/null
    log "network ${NETWORK} created"
  fi
  if gc compute networks subnets describe "${SUBNET}" --region "${REGION}" >/dev/null 2>&1; then
    log "subnet ${SUBNET} exists"
  else
    gc compute networks subnets create "${SUBNET}" --network "${NETWORK}" \
      --region "${REGION}" --range "${SUBNET_RANGE}" >/dev/null
    log "subnet ${SUBNET} (${SUBNET_RANGE}) created"
  fi

  create_firewall_rule "${NAME}-allow-web" "tcp:80,tcp:443" "0.0.0.0/0"
  create_firewall_rule "${NAME}-allow-sip-rtp" "udp:5060,udp:${RTP_RANGE}" "0.0.0.0/0"
  create_firewall_rule "${NAME}-allow-ssh" "tcp:22" "${SSH_CIDR},${IAP_RANGE}"

  if gc compute addresses describe "${ADDRESS}" --region "${REGION}" >/dev/null 2>&1; then
    log "static IP ${ADDRESS} exists"
  else
    gc compute addresses create "${ADDRESS}" --region "${REGION}" >/dev/null
    log "static IP ${ADDRESS} reserved"
  fi
  local ip
  ip="$(gc compute addresses describe "${ADDRESS}" --region "${REGION}" --format='value(address)')"

  if gc compute instances describe "${NAME}" --zone "${ZONE}" >/dev/null 2>&1; then
    log "VM ${NAME} exists; not touching it"
  else
    gc compute instances create "${NAME}" --zone "${ZONE}" \
      --machine-type "${MACHINE_TYPE}" \
      --image-family "${IMAGE_FAMILY}" --image-project "${IMAGE_PROJECT}" \
      --boot-disk-size "${DISK_SIZE_GB}GB" --boot-disk-type pd-balanced \
      --subnet "${SUBNET}" --address "${ip}" --tags "${TAG}" \
      --shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring \
      --metadata-from-file "user-data=${cloud_init}" >/dev/null
    log "VM ${NAME} (${MACHINE_TYPE}) created in ${ZONE}"
  fi

  cat <<EOF

Aavaz PBX is installing (about 3 minutes).
  Public IP      : ${ip}   (give this to your SIP trunk provider)
  Management UI  : https://${ip}/   (self-signed certificate warning is expected)
  SSH            : gcloud compute ssh ${NAME} --zone ${ZONE} --project ${PROJECT}
  Install log    : sudo tail -f /var/log/cloud-init-output.log   (on the VM)
  Next step      : log in, change the admin password, open your current IP for SIP.
  Remove it all  : $0 --project ${PROJECT} --zone ${ZONE} --name ${NAME} --delete
EOF
}

function delete_all() {
  log "deleting ${NAME} and its network, firewall rules and static IP in ${PROJECT}"
  gc compute instances delete "${NAME}" --zone "${ZONE}" 2>/dev/null \
    && log "VM deleted" || log "no VM ${NAME}"
  local rule
  for rule in "${NAME}-allow-web" "${NAME}-allow-sip-rtp" "${NAME}-allow-ssh"; do
    gc compute firewall-rules delete "${rule}" 2>/dev/null \
      && log "firewall rule ${rule} deleted" || log "no firewall rule ${rule}"
  done
  gc compute addresses delete "${ADDRESS}" --region "${REGION}" 2>/dev/null \
    && log "static IP released" || log "no static IP ${ADDRESS}"
  gc compute networks subnets delete "${SUBNET}" --region "${REGION}" 2>/dev/null \
    && log "subnet deleted" || log "no subnet ${SUBNET}"
  gc compute networks delete "${NETWORK}" 2>/dev/null \
    && log "network deleted" || log "no network ${NETWORK}"
}

function main() {
  parse_args "$@"
  command -v gcloud >/dev/null || die "gcloud not found (use Cloud Shell, or install the Google Cloud CLI)"
  if (( DELETE )); then
    delete_all
  else
    deploy
  fi
}

main "$@"
