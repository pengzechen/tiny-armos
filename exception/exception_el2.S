

.extern vm_in
.extern vm_out

.macro SAVE_REGS_EL2
    sub     sp, sp,   34 * 8
    stp     x0, x1,   [sp, 2 * 0]
    stp     x2, x3,   [sp, 2 * 8]
    stp     x4, x5,   [sp, 4 * 8]
    stp     x6, x7,   [sp, 6 * 8]
    stp     x8, x9,   [sp, 8 * 8]
    stp     x10, x11, [sp, 10 * 8]
    stp     x12, x13, [sp, 12 * 8]
    stp     x14, x15, [sp, 14 * 8]
    stp     x16, x17, [sp, 16 * 8]
    stp     x18, x19, [sp, 18 * 8]
    stp     x20, x21, [sp, 20 * 8]
    stp     x22, x23, [sp, 22 * 8]
    stp     x24, x25, [sp, 24 * 8]
    stp     x26, x27, [sp, 26 * 8]
    stp     x28, x29, [sp, 28 * 8]

    mov     x1, sp
    add     x1, x1,   #(0x110)   // 34 * 8
    stp     x30, x1,  [sp, 30 * 8]
    mrs     x10, elr_el2
    mrs     x11, spsr_el2
    stp     x10, x11, [sp, 32 * 8]

    bl      vm_out
.endm

.macro RESTORE_REGS_EL2
    bl      vm_in

    ldp     x10, x11, [sp, 32 * 8]
    msr     elr_el2, x10
    msr     spsr_el2, x11

    ldr     x30,      [sp, 30 * 8]
    ldp     x28, x29, [sp, 28 * 8]
    ldp     x26, x27, [sp, 26 * 8]
    ldp     x24, x25, [sp, 24 * 8]
    ldp     x22, x23, [sp, 22 * 8]
    ldp     x20, x21, [sp, 20 * 8]
    ldp     x18, x19, [sp, 18 * 8]
    ldp     x16, x17, [sp, 16 * 8]
    ldp     x14, x15, [sp, 14 * 8]
    ldp     x12, x13, [sp, 12 * 8]
    ldp     x10, x11, [sp, 10 * 8]
    ldp     x8, x9,   [sp, 8 * 8]
    ldp     x6, x7,   [sp, 6 * 8]
    ldp     x4, x5,   [sp, 4 * 8]
    ldp     x2, x3,   [sp, 2 * 8]
    ldp     x0, x1,   [sp, 2 * 0]
    add     sp, sp, 34 * 8
.endm


.macro INVALID_EXCP_EL2, kind, source
.p2align 7
    SAVE_REGS_EL2
    mov     x0, sp
    mov     x1, \kind
    mov     x2, \source
    bl      invalid_exception_el2
    b       .Lexception_return_el2
.endm

.macro HANDLE_CURRENT_IRQ
.p2align 7
    SAVE_REGS_EL2
    mov     x0, sp
    bl      current_spxel_irq
    b       .Lexception_return_el2
.endm

.macro HANDLE_LOWER_IRQ
.p2align 7
    SAVE_REGS_EL2
    mov     x0, sp
    bl      handle_irq_exception_el2
    b       .Lexception_return_el2
.endm

.macro HANDLE_LOWER_SYNC
.p2align 7
    SAVE_REGS_EL2
    mov     x0, sp
    bl      handle_sync_exception_el2
    b       .Lexception_return_el2
.endm


.section .text
# .section .el2code
.p2align 11
.global exception_vector_base_el2
exception_vector_base_el2:
    // current EL, with SP_EL0
    INVALID_EXCP_EL2 0 0
    INVALID_EXCP_EL2 1 0
    INVALID_EXCP_EL2 2 0
    INVALID_EXCP_EL2 3 0

    // current EL, with SP_ELx
    INVALID_EXCP_EL2 0 1
    HANDLE_CURRENT_IRQ
    INVALID_EXCP_EL2 2 1
    INVALID_EXCP_EL2 3 1

    // lower EL, aarch64  比当前等级更低一级
    HANDLE_LOWER_SYNC
    HANDLE_LOWER_IRQ
    INVALID_EXCP_EL2 2 2
    INVALID_EXCP_EL2 3 2

    // lower EL, aarch32
    INVALID_EXCP_EL2 0 3
    INVALID_EXCP_EL2 1 3
    INVALID_EXCP_EL2 2 3
    INVALID_EXCP_EL2 3 3

.Lexception_return_el2:
    RESTORE_REGS_EL2
    eret


// ldp x1, x2, [x0], #16: 从 x0 寄存器指向的内存地址中加载两个64位值到 x1 和 x2 寄存器，然后将 x0 增加16字节。

.global guest_entry
guest_entry:

    bl      vm_in        //  恢复当前 vm 的系统寄存器
    ldp     x10, x11, [sp, 32 * 8]
    msr     elr_el2, x10
    msr     spsr_el2, x11

    ldr     x30,      [sp, 30 * 8]
    ldp     x28, x29, [sp, 28 * 8]
    ldp     x26, x27, [sp, 26 * 8]
    ldp     x24, x25, [sp, 24 * 8]
    ldp     x22, x23, [sp, 22 * 8]
    ldp     x20, x21, [sp, 20 * 8]
    ldp     x18, x19, [sp, 18 * 8]
    ldp     x16, x17, [sp, 16 * 8]
    ldp     x14, x15, [sp, 14 * 8]
    ldp     x12, x13, [sp, 12 * 8]
    ldp     x10, x11, [sp, 10 * 8]
    ldp     x8, x9,   [sp, 8 * 8]
    ldp     x6, x7,   [sp, 6 * 8]
    ldp     x4, x5,   [sp, 4 * 8]
    ldp     x2, x3,   [sp, 2 * 8]
    ldp     x0, x1,   [sp, 2 * 0]
    add     sp, sp,   34 * 8

    eret