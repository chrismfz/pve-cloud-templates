# Δημιουργία νέου VM από template

> Μέχρι να γραφτεί το `newvm` script, αυτά είναι τα βήματα με το χέρι.
> Έτοιμο αντίγραφο: [`examples/new-vm.sh`](../examples/new-vm.sh).

## Πριν ξεκινήσεις

- **VMID**: στη MyIP το VMID = id υπηρεσίας στο WHMCS (το θέλει το pvewhmcs).
- **IP**: ελεύθερη από το 84.54.49.0/24 (δες ότι δεν είναι σε ενεργή υπηρεσία).
- **Node**: template 90xx αν φτιάχνεις στον vega, 91xx στον pegasus.

## Βήματα (παράδειγμα: Cloud 1 + 2 vCPU extra, Debian 13, στον vega)

```bash
VMID=2690; NAME=vm.example.gr; IP=84.54.49.15; TPL=9000
CORES_MAX=8; VCPUS=4; RAM=4096; DISK=50G
CIUSER=admin; SSHKEY=/root/keys/customer.pub     # το κλειδί του πελάτη

qm clone $TPL $VMID --name $NAME --full 1 --storage local-zfs
qm set $VMID --cores $CORES_MAX --vcpus $VCPUS --memory $RAM \
  --ciuser $CIUSER --cipassword "$(openssl rand -base64 18)" --sshkeys $SSHKEY \
  --ipconfig0 ip=$IP/24,gw=84.54.49.1 \
  --nameserver "1.1.1.1 9.9.9.9" --searchdomain myip.gr \
  --onboot 1 --tags clients
qm resize $VMID scsi0 $DISK
```

### Anti-spoofing (ΠΑΝΤΑ)

```bash
cat > /etc/pve/firewall/$VMID.fw <<EOF
[OPTIONS]
enable: 1
ipfilter: 1
policy_in: ACCEPT
policy_out: ACCEPT

[IPSET ipfilter-net0] # anti-spoofing
$IP
EOF
```

> `policy_in: ACCEPT` είναι **υποχρεωτικό** — το default του VM firewall
> είναι DROP. IPv6: πρόσθεσε το EUI-64 του VM (μετά το 1ο boot, από
> `qm guest cmd $VMID network-get-interfaces`).

### Backup (αν το πακέτο έχει daily)

```bash
pvesh create /cluster/backup --vmid $VMID --schedule '01:30' \
  --storage vaultserres --mode snapshot --compress zstd \
  --prune-backups keep-last=7 --comment "$NAME daily (7d)" --enabled 1
```
(`schedule` = σκέτη ώρα για «κάθε μέρα»· το `daily 01:30` **δεν** γίνεται δεκτό.)

### Start + έλεγχος

```bash
qm start $VMID
# ~1 λεπτό: ο agent ανεβαίνει μόλις το cloud-init εγκαταστήσει πακέτα
qm agent $VMID ping && qm guest exec $VMID -- cloud-init status
```

Περιμένεις `status: done`. Μετά:

- `ssh admin@$IP` (κλειδί ή password), `sudo` ζητάει password
- `ssh root@$IP` μόνο με κλειδί
- WHMCS: γραμμή στο `mod_pvewhmcs_vms` (id=VMID, vmid=VMID, vtype=qemu, ipaddress=$IP)
  ή Addons → Proxmox VE for WHMCS → Import Guest

## Αναβάθμιση αργότερα (live, χωρίς reboot)

```bash
qm set $VMID --vcpus 6        # μέχρι το CORES_MAX
qm set $VMID --memory 8192
qm resize $VMID scsi0 +20G    # μέσα στο VM: growpart + resize2fs/xfs_growfs
```
