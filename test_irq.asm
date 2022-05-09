asect 0xf3
IOReg: # Gives the address 0xf3 the symbolic name IOReg
asect 0x00
br main

irq:
	inc r0
	rti

main:
	addsp -16
	ei	
	ldi r0, IOReg # Load the address of the keyboard and display in r0
readkbd:
	do
		ld r0,r1
		tst r1
	until pl
		st r0,r1
	br readkbd
	
loop:
	wait
	br loop
	
asect 0xf0
dc irq
end