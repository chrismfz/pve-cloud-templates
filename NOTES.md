# NOTES — τι μάθαμε (διάβασε πριν αλλάξεις κάτι)

Μαζεμένα από το στήσιμο της 2026-11-05/06.

## Hotplug & NUMA

- **RAM hotplug** θέλει `numa: 1` + `memory` στο `hotplug`. Χωρίς balloon, χωρίς hugepages.
- **vCPU hotplug** θέλει `cores` = ταβάνι (π.χ. 8) και `vcpus` = ενεργές (π.χ. 4).
  Ο πελάτης βλέπει/χρησιμοποιεί μόνο τα `vcpus`.
- Οι νέες vCPUs **μένουν offline** στον guest χωρίς udev κανόνα
  (Debian 13 το επιβεβαίωσε: `cpu2=0 cpu3=0`). Ο κανόνας είναι στο vendor snippet:
  `SUBSYSTEM=="cpu", ACTION=="add", TEST=="online", ATTR{online}=="0", ATTR{online}="1"`.
  VMs παλιότερα από τα templates (π.χ. 2688 ipvoice) **δεν** τον έχουν.
- Αλλαγή `hotplug`/`numa` σε υπάρχον VM ισχύει μόνο μετά από **stop + start**
  (όχι reboot από μέσα).

## Proxmox

- Το `description` του VM αποθηκεύεται URL-encoded (`:` → `%3A`), οπότε **μην** κρατάς
  machine-readable δεδομένα εκεί. Το checksum του image κρατιέται στο
  `/var/lib/vz/template/cloud/.<vmid>.sum`.
- `pvesh create /cluster/backup --schedule`: «κάθε μέρα 01:30» γράφεται `01:30`,
  όχι `daily 01:30`.
- `local-zfs` δεν είναι κοινό → ένα σετ templates ανά node. Όταν έρθει Ceph, ένα σετ αρκεί.
- `qm clone --full 1` πάντα: τα VMs να μην εξαρτώνται από το template.

## Firewall / anti-spoofing

- Το `firewall=1` στη NIC **δεν** αρκεί. Χρειάζεται `/etc/pve/firewall/<vmid>.fw`
  με `enable: 1` + `ipfilter: 1` + `policy_in: ACCEPT` (default του VM fw = DROP).
- Τα VMs μοιράζονται το `2a14:4280:1:1::/64` → στο ipset βάζουμε το **/128** του VM,
  όχι όλο το /64 (εκτός από Windows με privacy extensions).
- Το `ipfilter` καλύπτει και ARP· ο raw κανόνας στο MikroTik μόνο IP.
- Dedicated/colo (χωρίς Proxmox από κάτω): κλείδωμα μόνο από MikroTik
  (raw ανά MAC + address-list).

## Cloud-init

- Το vendor snippet διαβάζεται **μία φορά** (1ο boot). Αλλαγές του επηρεάζουν
  μόνο νέα VMs — δεν χρειάζεται rebuild templates.
- Τα cloud images έχουν ήδη `sudo` (σε αντίθεση με Debian netinst minimal).
- Το cloud-init βάζει `NOPASSWD` στο sudo· το snippet το αφαιρεί.
- `disable_root: false` → τα ίδια SSH keys μπαίνουν και στον root·
  με `PermitRootLogin prohibit-password` root μόνο με κλειδί.
- Ubuntu **minimal** ≠ cloud image. Αν κάποιος έστησε minimal από ISO:
  `apt install unminimize && unminimize`.

## AlmaLinux 10

- Θέλει CPU **x86-64-v3** (AVX2). vega (E5-2699 v3) και pegasus (E5-2640 v4): OK.
