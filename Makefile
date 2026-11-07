obj-m += asus_ec_wake.o

KVER ?= $(shell uname -r)

# CachyOS kernels are built with clang, so the module must be too.
all:
	$(MAKE) -C /usr/lib/modules/$(KVER)/build M=$(CURDIR) LLVM=1 modules

clean:
	$(MAKE) -C /usr/lib/modules/$(KVER)/build M=$(CURDIR) LLVM=1 clean
