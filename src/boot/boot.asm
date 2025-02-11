;bootloader for my OS
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
