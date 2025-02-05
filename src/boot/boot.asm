;bootloader for my OS
ORG 0x7C00
BITS 16

main:
	HLT

.halt:
	JMP .halt

TIMES $10-($-$$) DW 0
DW 0AA5h
