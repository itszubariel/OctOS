bits 32

MAGIC                equ 0xE85250D6
ARCH                 equ 0 << 0
HEADER_LENGTH        equ multiboot_header_end - multiboot_header_start
CHECKSUM             equ -(MAGIC + ARCH + HEADER_LENGTH)
BOOT_SERVICES_TAG    equ 1 << 0 | 1 << 1 | 1 << 2
END_TAG              equ 0 << 0
FLAGS_TAG            equ 0 << 0
                         ; Presentable        ; Writeable
PRESENT_AND_WRITABLE equ 1 << 0       |       1 << 1
HUGE_PAGE_FLAGS      equ 1 << 7
CR4_PAE              equ 1 << 5
CR0_PG_PM_ENABLE     equ 1 << 0 | 1 << 31
EFER_MSR             equ 0xC0000080
EFER_LME              equ 1 << 8


section .multiboot
align 8
multiboot_header_start:
    dd MAGIC
    dd ARCH
    dd HEADER_LENGTH
    dd CHECKSUM

    ; Prevent GRUB from calling ExitBootServices.
    align 8
    dw BOOT_SERVICES_TAG
    dw FLAGS_TAG
    dd 8

    align 8
    dw END_TAG
    dw FLAGS_TAG
    dd 8
multiboot_header_end:

section .bss
align 4096
pml4:
    resb 4096
pdpt:
    resb 4096
pd:
    resb 4096

align 16
stack_bottom:
    resb 16384
stack_top:

align 4
multiboot_magic:
    resd 1
multiboot_info:
    resd 1

section .rodata
align 8
gdt64:
    dq 0

gdt64.code_segment: equ $ - gdt64
    ; Executable           ; Desc type         ; Present           ; Flags
    dq 1 << 43      |      1 << 44      |      1 << 47      |      1 << 53

gdt64.pointer:
    dw $ - gdt64 - 1
    dq gdt64

section .text
global _start
_start:
    cli

    mov [multiboot_magic], eax
    mov [multiboot_info], ebx

    mov esp, stack_top ; Move the stack pointer to the stack top.

    ; Now we need to switch to 64-bit long mode.

    ; Link PML4 to PDPT.
    mov eax, pdpt
    or eax, PRESENT_AND_WRITABLE
    mov [pml4], eax
    mov dword [pml4 + 4], 0

    ; Links PDPT to PD.
    mov eax, pd
    or eax, PRESENT_AND_WRITABLE
    mov [pdpt], eax
    mov dword [pdpt + 4], 0

    ; Identity mapping.
    mov ecx, 0
.map_pd_table:
    mov eax, ecx
    shl eax, 21
    or eax, 0x83

    mov [pd + ecx * 8], eax
    mov dword [pd + ecx * 8 + 4], 0

    inc ecx
    cmp ecx, 512
    jne .map_pd_table

    ; CR3.
    mov eax, pml4
    mov cr3, eax

    ; Enable PAE.
    mov eax, cr4
    or eax, CR4_PAE
    mov cr4, eax

    ; Compability mode.
    mov ecx, EFER_MSR
    rdmsr
    or eax, EFER_LME
    wrmsr

    ; Enable paging.
    mov eax, cr0
    or eax, CR0_PG_PM_ENABLE
    mov cr0, eax

    ; Long jump.
    lgdt [gdt64.pointer]
    jmp gdt64.code_segment:init_64

bits 64
init_64:
    ; Reset segment registers
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax

    mov rsp, stack_top ; Upgrade the stack pointer to 64-bit.

    mov edi, [multiboot_magic]
    mov esi, [multiboot_info]

    extern kernel_main
    call kernel_main

    .halt:
        hlt
        jmp .halt
