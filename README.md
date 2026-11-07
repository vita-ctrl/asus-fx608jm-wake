# asus-ec-wake

Фикс: ноутбук **ASUS TUF Gaming F16 FX608JM** не просыпается при открытии крышки
из сна (`s2idle`) на Linux (CachyOS). Будил только клик по тачпаду.
Закрытие крышки при этом усыпляло нормально.

## Причина

В `s2idle` событие открытия крышки приходит от встроенного контроллера (EC)
через ACPI GPE `0x14`. Ядро не считает этот GPE способным будить систему
(`acpi_set_gpe_wake_mask` возвращает `AE_TYPE`), поэтому событие не будит
ноутбук. В логе видно:

```
PM: Triggering wakeup from IRQ 14      # тачпад
ACPI: PM: Wakeup unrelated to ACPI SCI
```

Модуль помечает GPE `0x14` как способный будить (`acpi_mark_gpe_for_wake`) и
включает его в маску пробуждения (`acpi_set_gpe_wake_mask`). Больше ничего
не меняется: ни параметры ядра, ни GRUB, ни режим сна (остаётся `s2idle`).

Идея взята из
[Nixie404/asus-fx607-wake](https://github.com/Nixie404/asus-fx607-wake)
(та же проблема на FX607VJ, там GPE `0x02`).

## Установка (после переустановки системы)

Нужны `dkms`, `clang`, `lld` и заголовки ядра (ядра CachyOS собираются clang):

```bash
sudo pacman -S --needed dkms clang lld linux-cachyos-headers
git clone <URL_ЭТОГО_РЕПОЗИТОРИЯ> asus-ec-wake
cd asus-ec-wake
sudo ./install.sh
```

Скрипт:
1. проверяет, что это FX608JM (по DMI);
2. копирует исходники в `/usr/src/asus-ec-wake-1.0`;
3. ставит модуль через DKMS (будет пересобираться при обновлении ядра);
4. добавляет `/etc/modules-load.d/asus_ec_wake.conf` (автозагрузка);
5. загружает модуль сразу.

Если используется другое ядро (например `linux-cachyos-lts`), поставьте
соответствующие `*-headers`.

## Проверка

```bash
lsmod | grep asus_ec_wake
journalctl -k -b | grep asus_ec_wake      # asus_ec_wake: GPE 14 armed for wake
dkms status
```

Потом закройте крышку, подождите 10–15 секунд и откройте. Ноутбук должен
проснуться без касания тачпада.

## Удаление

```bash
sudo ./uninstall.sh
```

## Заметки

- Модуль загружается только на машинах, где `product_name` содержит `FX608JM`;
  на других отказывается (`-ENODEV`).
- Внешний модуль помечает ядро как tainted. Это нормально для DKMS.
- Если при включённом Secure Boot модуль не загружается, нужно зарегистрировать
  ключ DKMS (`/var/lib/dkms/mok.pub`) через `mokutil --import`.
- Для другой модели ASUS номер GPE может отличаться. Его можно найти, сравнив
  счётчики `/sys/firmware/acpi/interrupts/gpe*` до и после открытия и закрытия
  крышки (растёт именно GPE крышки), и поменять `TARGET_GPE` в `asus_ec_wake.c`.

## Лицензия

GPL-2.0 (см. `SPDX-License-Identifier` в `asus_ec_wake.c`).
