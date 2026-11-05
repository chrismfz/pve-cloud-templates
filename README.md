# pve-cloud-templates

Cloud-init templates για το Proxmox cluster της MyIP (vega, pegasus).
Ένα νέο VM με OS έτοιμο, static IP, χρήστη/κλειδί, guest agent, NUMA και
live hotplug — σε ~1 λεπτό, χωρίς installer.

> **Αν θυμάσαι ένα πράγμα:** δεν φτιάχνουμε δικά μας images. Παίρνουμε τα
> επίσημα cloud images της κάθε διανομής (αυτές τα συντηρούν) και τους
> «κολλάμε» τις δικές μας ρυθμίσεις. Η συντήρηση είναι μια γραμμή σε ένα
> αρχείο κειμένου.

## Τι υπάρχει εδώ

| Αρχείο | Τι κάνει |
|---|---|
| `etc/os.list` | **Ποια OS** έχουμε (μια γραμμή το καθένα). Εδώ προσθέτεις νέα έκδοση. |
| `etc/nodes.list` | **Ποιοι nodes** και ποιο εύρος VMID παίρνει ο καθένας (vega 90xx, pegasus 91xx). |
| `bin/refresh-templates` | Κατεβάζει τα images, ελέγχει checksum, φτιάχνει/ανανεώνει τα templates. |
| `snippets/myip-vendor.yaml` | Οι κοινές ρυθμίσεις που εφαρμόζονται **μέσα** σε κάθε νέο VM στο 1ο boot. |
| `install.sh` | Στήνει έναν node από το μηδέν (ή τον ενημερώνει μετά από `git pull`). |
| `docs/` | Οδηγίες βήμα-βήμα. |
| `NOTES.md` | Τι μάθαμε / παγίδες. **Διάβασέ το πριν αλλάξεις κάτι.** |
| `examples/` | Έτοιμες εντολές για νέο VM, cron κλπ. |

## Οδηγίες

1. [Πώς δουλεύει (τα 2 κομμάτια του cloud-init)](docs/01-how-it-works.md)
2. [Στήσιμο σε νέο node από το μηδέν](docs/02-new-node.md)
3. [Προσθήκη νέου OS / νέας έκδοσης](docs/03-add-os.md)
4. [Δημιουργία νέου VM από template](docs/04-new-vm.md)
5. [Troubleshooting](docs/05-troubleshooting.md)

## Γρήγορα

```bash
# σε κάθε node, μία φορά
git clone https://github.com/chrismfz/pve-cloud-templates /opt/pve-cloud-templates
/opt/pve-cloud-templates/install.sh

# μετά από αλλαγή στο repo
cd /opt/pve-cloud-templates && git pull && ./install.sh

# τι templates έχει αυτός ο node
refresh-templates --list
```

## Templates (σήμερα)

| OS | vega | pegasus |
|---|---|---|
| Debian 13 (trixie) | 9000 | 9100 |
| Ubuntu 24.04 LTS (noble) | 9001 | 9101 |
| Ubuntu 26.04 LTS (resolute) | 9002 | 9102 |
| AlmaLinux 10 | 9003 | 9103 |

Όλα: `cpu host`, `numa 1`, `hotplug disk,network,usb,memory,cpu`, guest agent,
virtio-scsi-single + iothread, NIC με `firewall=1`, cloud-init drive στο `ide2`,
σε `local-zfs`. Τα VMs φτιάχνονται **πάντα ως full clone** — δεν εξαρτώνται από
το template μετά τη δημιουργία τους.
