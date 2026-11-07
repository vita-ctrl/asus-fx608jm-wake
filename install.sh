#!/bin/bash
# Установка модуля asus_ec_wake через DKMS + автозагрузка. Запускать от root:
#   sudo ./install.sh
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Запустите от root: sudo $0" >&2
    exit 1
fi

DIR="$(cd "$(dirname "$0")" && pwd)"
NAME=asus-ec-wake
VER=1.0
SRC=/usr/src/$NAME-$VER

# Проверка модели: модуль рассчитан только на FX608JM.
PRODUCT="$(cat /sys/class/dmi/id/product_name)"
if [[ "$PRODUCT" != *FX608JM* ]]; then
    echo "Это не ASUS FX608JM (product_name: $PRODUCT). Модуль не подойдёт, выхожу." >&2
    exit 1
fi

# Зависимости.
for cmd in dkms clang ld.lld; do
    command -v "$cmd" >/dev/null || {
        echo "Нет '$cmd'. Установите: sudo pacman -S dkms clang lld linux-cachyos-headers" >&2
        exit 1
    }
done
[ -d "/usr/lib/modules/$(uname -r)/build" ] || {
    echo "Нет заголовков ядра для $(uname -r). Установите linux-cachyos-headers (или заголовки своего ядра)." >&2
    exit 1
}

# Убрать прошлую установку, если была.
if dkms status -m "$NAME" -v "$VER" 2>/dev/null | grep -q "$NAME"; then
    dkms remove "$NAME/$VER" --all || true
fi
rm -rf "$SRC"

mkdir -p "$SRC"
cp "$DIR/asus_ec_wake.c" "$DIR/Makefile" "$DIR/dkms.conf" "$SRC/"

dkms add -m "$NAME" -v "$VER"
dkms install -m "$NAME" -v "$VER"

echo asus_ec_wake > /etc/modules-load.d/asus_ec_wake.conf
modprobe asus_ec_wake

echo
dkms status -m "$NAME"
dmesg | grep asus_ec_wake | tail -1 || true
echo "Готово. Проверьте: закройте крышку, подождите 10-15 с, откройте."
