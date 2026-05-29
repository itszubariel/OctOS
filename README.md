# OctOS

A hobby x86_64 operating system kernel that boots from GRUB via Multiboot2, configures 64-bit Long Mode, and runs a basic C kernel.

---

## Features

* **Multiboot2 Compliant:** Bootable by GRUB using a native Multiboot2 header.
* **64-bit Long Mode Switch:** Switches architecture execution from 32-bit Protected Mode to 64-bit Long Mode.
* **Identity Paging:** Sets up initial 3-tier paging (PML4, PDPT, PD) to map the first gigabyte of memory with 2MB huge pages.
* **Reproducible Toolchain:** Uses Nix to automatically manage cross-compilation tools.

---

## Structure

* **`kernel/arch/x86_64/boot.asm`**: Initial assembly setup, paging initialization, and long jump to 64-bit mode.
* **`kernel/kernel/kernel.c`**: C entry point (`kernel_main`) that verifies the bootloader magic number.
* **`kernel/arch/x86_64/linker.ld`**: Directs sections to load starting at the 1MB mark.
* **`isodir/boot/grub/grub.cfg`**: GRUB configuration to load the `octos.bin` kernel.
* **`toolchain/default.nix`**: Nix configuration environment managing the required build tools.

---

## Environment Setup

To drop into a shell containing the `x86_64-embedded` GCC cross-compiler, binutils, and NASM:

```bash
nix-shell toolchain/default.nix
