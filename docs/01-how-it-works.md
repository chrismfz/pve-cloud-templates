# Πώς δουλεύει

## Το template δεν είναι «εγκατάσταση»

Κανένα template δεν έχει εκκινήσει ποτέ. Φτιάχνεται έτσι (`bin/refresh-templates`):

1. `qm create` → ένα **άδειο VM**, μόνο «hardware» (CPU, NUMA, hotplug, NIC, agent).
2. Import του **επίσημου cloud image** ως δίσκο `scsi0`. Το image *είναι ήδη*
   εγκατεστημένο OS — το έφτιαξε η διανομή (Debian/Ubuntu/Alma), όχι εμείς.
3. Προσθήκη **cloud-init drive** (`ide2`) — ένα μικρό εικονικό CD-ROM.
4. `qm template` → κλειδώνει. Δεν ξεκινάει, μόνο κλωνοποιείται.

Επειδή δεν ξεκίνησε ποτέ, δεν έχει SSH host keys / machine-id / hostname —
αυτά φτιάχνονται ξεχωριστά σε κάθε clone στο 1ο boot. Γι' αυτό τα clones δεν
«συγκρούονται» μεταξύ τους.

## Τα 2 κομμάτια του cloud-init

```
 ┌─ Proxmox (καρτέλα Cloud-Init) ─┐        ┌─ μέσα στο OS (στο image) ─┐
 │ user, password, SSH key, IP,   │ ──►    │ πρόγραμμα «cloud-init»     │
 │ DNS + vendor snippet           │  ISO   │ διαβάζει το CD στο 1ο boot │
 │ → φτιάχνει μικρό ISO (ide2)    │        │ και ρυθμίζει τα πάντα      │
 └────────────────────────────────┘        └────────────────────────────┘
```

- **Καρτέλα Cloud-Init στο Proxmox** = η *φόρμα*. Από αυτήν το Proxmox φτιάχνει
  το μικρό ISO. Υπάρχει σε **όλα** τα VMs, αλλά σε όσα στήθηκαν από ISO δεν
  κάνει τίποτα (δεν έχουν ούτε cloud-init drive ούτε το πρόγραμμα μέσα τους).
- **Πρόγραμμα `cloud-init` μέσα στο OS** = αυτό που *κάνει* τη δουλειά.

## Τι ρυθμίζεται από πού

| Ρύθμιση | Από πού | Πότε |
|---|---|---|
| hostname, user, password, SSH keys, IP, DNS | Proxmox (`qm set --ciuser … --ipconfig0 …`) | ανά VM |
| timezone, πακέτα, `apt/dnf upgrade`, sshd, sudo, udev hotplug | `snippets/myip-vendor.yaml` | κοινά για όλα |
| CPU/RAM/δίσκος/NUMA/hotplug/firewall | template (+ `qm set` στο clone) | ανά VM |

Το vendor snippet διαβάζεται **μόνο στο 1ο boot**. Αλλαγή του δεν επηρεάζει
υπάρχοντα VMs — μόνο όσα φτιαχτούν μετά. Δεν χρειάζεται rebuild των templates.

## Γιατί δεν θέλει «νταντά»

- Νέα έκδοση image → το `refresh-templates` (cron μηνιαία) κατεβάζει το νέο
  μόνο αν άλλαξε το checksum και ξαναφτιάχνει το template με τις ίδιες ρυθμίσεις.
- Παλιό template; Δεν πειράζει: κάθε νέο VM κάνει `upgrade` στο 1ο boot.
- Νέα major έκδοση → μία γραμμή στο `etc/os.list` ([οδηγία](03-add-os.md)).
