#!/usr/bin/env bash
# Set up (or update) a Proxmox node for MyIP cloud templates.
#
#   git clone https://github.com/chrismfz/pve-cloud-templates /opt/pve-cloud-templates
#   /opt/pve-cloud-templates/install.sh            # set up + build templates
#   /opt/pve-cloud-templates/install.sh --no-build # set up only
#
# Idempotent: safe to re-run after every `git pull`.
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
NODE="$(hostname -s)"
BUILD=1; [ "${1:-}" = "--no-build" ] && BUILD=0

command -v qm >/dev/null || { echo "this is not a Proxmox node (no qm)" >&2; exit 1; }
grep -vE '^\s*(#|$)' "$REPO/etc/nodes.list" | awk -F'|' '{gsub(/ /,"",$1); print $1}' | grep -qx "$NODE" \
  || { echo "node '$NODE' is missing from etc/nodes.list - add a line for it first" >&2; exit 1; }

echo "1/5 allow 'snippets' on the 'local' storage (cluster-wide, harmless if already set)"
cur=$(pvesm config local 2>/dev/null | awk '/^\s*content/{print $2}')
case ",$cur," in *,snippets,*) echo "    already enabled" ;; *) pvesm set local --content "${cur:+$cur,}snippets"; echo "    enabled" ;; esac

echo "2/5 install the cloud-init vendor snippet"
install -D -m 0644 "$REPO/snippets/myip-vendor.yaml" /var/lib/vz/snippets/myip-vendor.yaml

echo "3/5 link the command"
ln -sf "$REPO/bin/refresh-templates" /usr/local/sbin/refresh-templates
chmod 0755 "$REPO/bin/refresh-templates"

echo "4/5 monthly refresh (3rd of the month, 04:15)"
cat > /etc/cron.d/refresh-templates <<EOF
# MyIP: rebuild cloud templates whose upstream image changed (no-op otherwise)
15 4 3 * * root $REPO/bin/refresh-templates >> /var/log/refresh-templates.log 2>&1
EOF

echo "5/5 templates"
if [ "$BUILD" = 1 ]; then "$REPO/bin/refresh-templates"; else echo "    skipped (--no-build)"; fi
echo
"$REPO/bin/refresh-templates" --list
echo "done on $NODE"
