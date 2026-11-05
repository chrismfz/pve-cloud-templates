# Troubleshooting

| Σύμπτωμα | Αιτία / λύση |
|---|---|
| `refresh-templates` ξαναχτίζει κάθε φορά | Λείπει το `/var/lib/vz/template/cloud/.<vmid>.sum`. Φτιάχνεται μόνο του στο επόμενο build. |
| `CHECKSUM MISMATCH` | Η διανομή ανανέωνε το image την ώρα του download. Ξανατρέξε σε λίγο. |
| `node 'X' is not in etc/nodes.list` | Πρόσθεσε τον node ([02-new-node.md](02-new-node.md)). |
| `<vmid> exists and is NOT a template - refusing` | Κάποιος έβαλε κανονικό VM σε VMID template. Το script δεν το αγγίζει ποτέ — άλλαξε VMID. |
| Ο agent δεν ανεβαίνει ποτέ | Το VM δεν βγαίνει internet (λάθος IP/gw/DNS) → δεν κατεβαίνει το `qemu-guest-agent`. Κονσόλα (serial ή noVNC) και `cloud-init status --long`, `/var/log/cloud-init-output.log`. |
| vCPUs προστέθηκαν αλλά `nproc` ίδιο | Λείπει ο udev κανόνας (VM φτιαγμένο πριν το 2026-11-06 ή όχι από template): `/etc/udev/rules.d/80-hotplug-cpu-mem.rules` — δες `NOTES.md`. |
| RAM hotplug δεν δουλεύει | Θέλει `numa: 1` + `hotplug` με `memory` + **όχι** balloon/hugepages. Ενεργοποιείται μόνο μετά από ένα stop/start. |
| Το VM δεν δέχεται κίνηση μετά το `.fw` | Ξέχασες `policy_in: ACCEPT`. |
| IPv6 κόπηκε μετά από ipfilter | Το ipset έχει /128 αλλά ο guest αλλάζει διευθύνσεις (privacy extensions, π.χ. Windows). Βάλε το /64 ή απενεργοποίησε τα privacy extensions στον guest. |
| AlmaLinux 10 δεν κάνει boot | CPU χωρίς x86-64-v3 ([02-new-node.md](02-new-node.md)). |

## Χρήσιμες εντολές

```bash
refresh-templates --list                       # τι έχει ο node
qm config 9000                                 # ρυθμίσεις template
qm cloudinit dump <vmid> user                  # τι cloud-init θα πάρει το VM
qm cloudinit dump <vmid> network
tail -f /var/log/refresh-templates.log         # τελευταίο cron run
```
