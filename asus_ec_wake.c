// SPDX-License-Identifier: GPL-2.0
/*
 * ASUS TUF Gaming F16 FX608JM: the laptop does not wake from s2idle when the
 * lid is opened, because the embedded controller GPE (0x14), which delivers
 * the lid event, is not wake-capable. Mark it wake-capable and arm it.
 *
 * Idea from https://github.com/Nixie404/asus-fx607-wake
 * (same bug on another model, there it is GPE 0x02).
 */
#include <linux/acpi.h>
#include <linux/dmi.h>
#include <linux/init.h>
#include <linux/module.h>

#define TARGET_GPE 0x14
static bool armed;

static const struct dmi_system_id ids[] = {
	{ .matches = { DMI_MATCH(DMI_SYS_VENDOR, "ASUSTeK"),
		       DMI_MATCH(DMI_PRODUCT_NAME, "FX608JM") } },
	{ }
};

static int __init asus_ec_wake_init(void)
{
	acpi_status s;

	if (!dmi_check_system(ids))
		return -ENODEV;

	s = acpi_set_gpe_wake_mask(NULL, TARGET_GPE, ACPI_GPE_ENABLE);
	if (s == AE_TYPE) {
		/* GPE is not marked wake-capable yet: do it, then retry. */
		s = acpi_mark_gpe_for_wake(NULL, TARGET_GPE);
		if (ACPI_SUCCESS(s))
			s = acpi_set_gpe_wake_mask(NULL, TARGET_GPE, ACPI_GPE_ENABLE);
	}
	if (ACPI_FAILURE(s))
		return -EIO;

	armed = true;
	pr_info("asus_ec_wake: GPE %02x armed for wake\n", TARGET_GPE);
	return 0;
}

static void __exit asus_ec_wake_exit(void)
{
	if (armed)
		acpi_set_gpe_wake_mask(NULL, TARGET_GPE, ACPI_GPE_DISABLE);
}

module_init(asus_ec_wake_init);
module_exit(asus_ec_wake_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("ASUS FX608JM: arm EC GPE 0x14 for s2idle lid wake");
