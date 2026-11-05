# Στήσιμο σε νέο node από το μηδέν

Προϋποθέσεις: Proxmox VE 8.x/9.x, storage `local-zfs`, bridge `vmbr0`, internet
από τον node (κατεβάζει από cloud.debian.org, cloud-images.ubuntu.com, repo.almalinux.org).

## 1. Δήλωσε τον node στο repo

Στο `etc/nodes.list` πρόσθεσε μια γραμμή με **δικό του** εύρος VMID
(επόμενη εκατοντάδα), commit + push:

```
orion3 | 9200 | local-zfs | vmbr0
```

Αν ο node έχει άλλο storage ή bridge, γράψ' το εδώ.

## 2. Έλεγξε την CPU (για AlmaLinux 10)

Το Alma/RHEL 10 θέλει **x86-64-v3** (AVX2). Με `cpu: host`:

```bash
/lib64/ld-linux-x86-64.so.2 --help | grep x86-64-v3   # πρέπει να λέει "supported"
```

Αν όχι (πολύ παλιά CPU), βγάλε το alma από τον node ή πάρε το `x86_64_v2` image.

## 3. Εγκατάσταση

```bash
git clone https://github.com/chrismfz/pve-cloud-templates /opt/pve-cloud-templates
/opt/pve-cloud-templates/install.sh
```

Το `install.sh`:
1. ενεργοποιεί `snippets` στο storage `local` (cluster-wide, ακίνδυνο),
2. βάζει το `myip-vendor.yaml` στο `/var/lib/vz/snippets/`,
3. φτιάχνει το `/usr/local/sbin/refresh-templates` (symlink στο repo),
4. βάζει cron μηνιαίο (`/etc/cron.d/refresh-templates`),
5. χτίζει τα templates (~30″ το καθένα + download).

## 4. Επιβεβαίωση

```bash
refresh-templates --list
qm list | awk '$1>=9000 && $1<10000'
```

Μετά, κάνε ένα test VM ([04-new-vm.md](04-new-vm.md)) και σβήσ' το.
