# Προσθήκη νέου OS / νέας έκδοσης

Παράδειγμα: βγήκε Debian 14 (forky).

## 1. Βρες URL image + checksum

Τα μοτίβα είναι σταθερά:

| Διανομή | Image | Checksum |
|---|---|---|
| Debian | `cloud.debian.org/images/cloud/<codename>/latest/debian-<N>-genericcloud-amd64.qcow2` | `…/latest/SHA512SUMS` (sha512) |
| Ubuntu | `cloud-images.ubuntu.com/<codename>/current/<codename>-server-cloudimg-amd64.img` | `…/current/SHA256SUMS` (sha256) |
| AlmaLinux | `repo.almalinux.org/almalinux/<N>/cloud/x86_64/images/AlmaLinux-<N>-GenericCloud-latest.x86_64.qcow2` | `…/images/CHECKSUM` (sha256) |

Έλεγχος ότι υπάρχει:

```bash
curl -s https://cloud.debian.org/images/cloud/forky/latest/SHA512SUMS | grep genericcloud-amd64.qcow2
```

## 2. Μία γραμμή στο `etc/os.list`

Στο τέλος, με το **επόμενο ελεύθερο idx** (ποτέ μην ξαναχρησιμοποιήσεις παλιό):

```
4|debian-14|https://cloud.debian.org/images/cloud/forky/latest/debian-14-genericcloud-amd64.qcow2|https://cloud.debian.org/images/cloud/forky/latest/SHA512SUMS|sha512|l26
```

Commit + push.

## 3. Σε κάθε node

```bash
cd /opt/pve-cloud-templates && git pull
refresh-templates debian-14       # → 9004 στον vega, 9104 στον pegasus
```

## 4. Test

Ένα test VM από το νέο template ([04-new-vm.md](04-new-vm.md)): περίμενε
`cloud-init status: done`, έλεγξε SSH, `nproc`, ping. Σβήσ' το.

## Τι ΔΕΝ χρειάζεται

- Αλλαγή στο `myip-vendor.yaml` — χρησιμοποιεί κοινά ονόματα πακέτων.
- Σβήσιμο του παλιού OS — μένει δίπλα όσο θέλεις.

## Απόσυρση παλιού OS

1. Σβήσε (ή σχολίασε) τη γραμμή του από το `etc/os.list`, push.
2. Σε κάθε node: `qm destroy <vmid>` για το template του (π.χ. 9000 / 9100).
   Τα VMs που φτιάχτηκαν από αυτό δεν επηρεάζονται (full clones).
