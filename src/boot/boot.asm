;bootloader for my OS, most of these comments are for my self since assembly is still new to me!
ORG 0x7C00
BITS 16

%define ENDL 0x0D, 0x0A

start:
	jmp main


;prints a screen to the screen
;params:
;	. ds:si points to string

puts:
	push si
	push ax
.loop:
	lodsb	  ; loads next character
	or al, al ; verify if next character is null
	jz .done
	

	mov ah, 0x0e ;call bios interrupt
	mov bh, 0
	int 0x10

	jmp .loop
.done:
	pop ax
	pop si
	ret

load_kernel:
    mov ah, 0x02    ; BIOS read sector function
    mov al, 20      ; Number of sectors to read
    mov ch, 0x00    ; Cylinder 0
    mov dh, 0x00    ; Head 0
    mov cl, 0x02    ; Start reading from sector 2
    mov dl, 0x80    ; First hard drive
    mov bx, 0x1000  ; Load to 0x10000
    int 0x13        ; BIOS interrupt

    jc disk_error   ; If read fails, jump to error message

    ret             ; Return to caller

disk_error:
    mov si, error_msg
    call puts
    jmp $

error_msg: db "Disk read error!", ENDL, 0


gdt_start: ; Start of GDT needed for memory segmentation
	; null descriptor
	dq 0x0000000000000000  

	; code segment Descriptor (Base = 0x00000000, Limit = 0xFFFFFFFF, Type = 0x9A)
    dq 0x00CF9A000000FFFF  

	; Data Segment Descriptor (Base = 0x00000000, Limit = 0xFFFFFFFF, Type = 0x92)
    dq 0x00CF92000000FFFF  

gdt_end:   ; End of GDT

gdt_descriptor:
	dw gdt_end - gdt_start - 1 	; Size of gdt (16-bit)
	dd gdt_start 				; address of gdt (32-bit) 


;explanation, 
switch_to_pm:
	cli							;disable interrupts
	lgdt [gdt_descriptor] 		;load gdt
	mov eax, cr0				;Load control register 0 (cr = control register (duhhh))
	or eax, 0x1					;Set the PE (protection enable) bit
	mov cr0, eax 				;Write to cr0 (activates protected mode)

	jmp 0x08:protected_mode		;far jump (jump to any absolute address) to 32-bit protected mode (0x08 is the code segment selector)


[BITS 32]    ; Now we're in 32-bit mode!

protected_mode:
    mov ax, 0x10   ; 0x10 = Data segment selector (from GDT)
    mov ds, ax     ; Set Data Segment
    mov es, ax     ; Set Extra Segment
    mov fs, ax     ; Set FS Segment
    mov gs, ax     ; Set GS Segment
    mov ss, ax     ; Set Stack Segment
    mov esp, 0x9FBFF  ; Set stack pointer (any safe memory location is fine, i used this)

    call kernel_entry  ; Jump to kernel


kernel_entry:
    mov esi, 0x10000  
    mov edi, 0x100000 
    mov ecx, 512      

copy_kernel:
    mov eax, [esi]
    mov [edi], eax
    add esi, 4
    add edi, 4
    loop copy_kernel

    jmp 0x100000


main:
	;setup data segments
	mov ax, 0 ;cant write directly ds/es 
	mov ds, ax
	mov es, ax
	
	;setup stack
	mov ss, ax
	mov sp, 0x7C00

	; print message 
	mov si, msg_start
	call puts


	HLT

.halt:
	JMP .halt



msg_start: db "Welcome to my OS", ENDL, 0 

TIMES 510-($-$$) DB 0
DW 0xAA55
