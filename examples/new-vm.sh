#!/usr/bin/env bash
# Example: create a customer VM from a MyIP cloud template (manual, until `newvm` exists).
# Copy, edit the variables, run on the node that holds the template.
set -euo pipefail

VMID=2690                    # = WHMCS service id (pvewhmcs)
NAME=vm.example.gr
IP=84.54.49.15
TPL=9000                     # vega: 9000 debian-13, 9001 ubuntu-2404, 9002 ubuntu-2604, 9003 alma-10 (pegasus: 91xx)
CORES_MAX=8                  # hotplug ceiling
VCPUS=4                      # what the customer pays for
RAM=4096                     # MB
DISK=50G
CIUSER=admin
SSHKEY=/root/keys/customer.pub
DAILY_BACKUP=1               # 1 = add a daily backup job (7 days)

qm clone "$TPL" "$VMID" --name "$NAME" --full 1 --storage local-zfs
qm set "$VMID" --cores "$CORES_MAX" --vcpus "$VCPUS" --memory "$RAM" \
  --ciuser "$CIUSER" --cipassword "$(openssl rand -base64 18)" --sshkeys "$SSHKEY" \
  --ipconfig0 "ip=$IP/24,gw=84.54.49.1" \
  --nameserver "1.1.1.1 9.9.9.9" --searchdomain myip.gr \
  --onboot 1 --tags clients
qm resize "$VMID" scsi0 "$DISK"

cat > "/etc/pve/firewall/$VMID.fw" <<EOF
[OPTIONS]
enable: 1
ipfilter: 1
policy_in: ACCEPT
policy_out: ACCEPT

[IPSET ipfilter-net0] # anti-spoofing
$IP
EOF

if [ "$DAILY_BACKUP" = 1 ]; then
  pvesh create /cluster/backup --vmid "$VMID" --schedule '01:30' \
    --storage vaultserres --mode snapshot --compress zstd \
    --prune-backups keep-last=7 --comment "$NAME daily (7d)" --enabled 1
fi

qm start "$VMID"
echo "waiting for guest agent (cloud-init installs it on first boot)..."
for i in $(seq 1 60); do qm agent "$VMID" ping 2>/dev/null && break; sleep 3; done
qm guest exec "$VMID" -- cloud-init status --wait >/dev/null 2>&1 || true
qm guest exec "$VMID" -- cloud-init status
echo "IPv6 to add to the ipset (EUI-64):"
qm guest cmd "$VMID" network-get-interfaces | grep -o '"2a14:[^"]*"' || true
