#!/bin/bash
# Удаление модуля asus_ec_wake. Запускать от root:
#   sudo ./uninstall.sh
set -u

if [ "$EUID" -ne 0 ]; then
    echo "Запустите от root: sudo $0" >&2
    exit 1
fi

rmmod asus_ec_wake 2>/dev/null || true
dkms remove asus-ec-wake/1.0 --all 2>/dev/null || true
rm -f /etc/modules-load.d/asus_ec_wake.conf
rm -rf /usr/src/asus-ec-wake-1.0
echo "Удалено."
