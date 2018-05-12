#------------------------------------------------------
# 		col 0x1		col 0x2		col 0x4		col 0x8
#
# row 0x1	0		1		2		3	
#		0x11		0x21		0x41		0x81
#
# row 0x2	4		5		6		7
#		0x12		0x22		0x42		0x82
#
# row 0x4	8		9		a		b
#		0x14		0x24		0x44		0x84
#
# row 0x8	c		d		e		f
#		0x18		0x28		0x48		0x88
#
#------------------------------------------------------
# command row number of hexadecimal keyboard (bit 0 to 3)
# Eg. 	assign 0x1, to get key button 0,1,2,3
# 	assign 0x2, to get key button 4,5,6,7
# NOTE must reassign value for this address before reading,

.eqv IN_ADDRESS_HEXA_KEYBOARD 	0xFFFF0012

# receive row and column of the key pressed, 0 if not key pressed
# Eg. equal 0x11, means that key button 0 pressed.
# Eg. equal 0x28, means that key button D pressed.

.eqv OUT_ADDRESS_HEXA_KEYBOARD  	0xFFFF0014


.eqv KEY_CODE	0xFFFF0004	# ASCII code from keyboard, 1 byte
.eqv KEY_READY	0xFFFF0000	# =1 if has a new keycode ?
				# Auto clear after lw	

.eqv DISPLAY_CODE	0xFFFF000C 	# ASCII code to show, 1 byte
.eqv DISPLAY_READY	0xFFFF0008	# =1 if the display has already to do
					# Auto clear after sw

.data 
	newLine: .asciiz "\n"

		
.text
main:
	li	$t1, IN_ADDRESS_HEXA_KEYBOARD
	li	$t2, OUT_ADDRESS_HEXA_KEYBOARD
	
	li	$t6,KEY_CODE		# $t6: address of key_code
	li 	$t7,KEY_READY		# $t7: address of key_ready
		
	
	li	$k0,0
#============================================================
# Used registers: t1,t2,t3,t6,t7,t8,k0,k1,a0,a1,s0,s1,s2
#
#=============================================================
	
#======================================================
# GLOBAL VARIABLE
# 	$a1: current control code
#	$a2: keycode of enter or delete
#======================================================


#===================================================
# Read 3 consecutive input characters
# params:
#	$k1: order of character
#===================================================   
reset:
	li	$k1,0

read3ConsecutiveInput:
	addi	$k1,$k1,1
	beq	$k1,4,reset	
	

#======================================================
# Loop through 4 rows of number pad to scan all buttons
# parameter
#	$k0: row
#	$t3: hexa value of the checked row
#	$a0: scan code of key button
#	
#======================================================
loopThrough4Rows:
	addi	$k0,$k0,1	
	beq	$k0,1,checkFirstRow
	beq	$k0,2,checkSecondRow
	beq	$k0,3,checkThirdRow
	beq	$k0,4,checkFourthRow
	
	li	$k0,0			# keep scanning the number pad if no input found after scanning 4 rows
	j	loopThrough4Rows
	
#========================================================
# Scan through the selected row to find input
# param: 
#	$t3: selected row
#	$a0: hexa code of pressed button
#========================================================
polling:
	sb	$t3,0($t1)	# must reassign expected row
	lb	$a0,0($t2)	# read scan code of key button
	nop
	
	beq	$a0,0,loopThrough4Rows 		# scan next row if no input
	nop
	
#===================================
# Convert hexa keycode to hexa value
#====================================
	beq	$a0,0x11, set0
	beq	$a0,0x12, set4
	beq	$a0,0x14, set8
	beq	$a0,0x18, setC
	
	beq	$a0,0x21, set1
	beq	$a0,0x22, set5
	beq	$a0,0x24, set9
	beq	$a0,0x28, setD
	
	beq	$a0,0x41, set2
	beq	$a0,0x42, set6
	beq	$a0,0x44, setA
	beq	$a0,0x48, setE
	
	beq	$a0,0xffffff81, set3
	beq	$a0,0xffffff82, set7
	beq	$a0,0xffffff84, setB
	beq	$a0,0xffffff88, setF
	
#=================================================
# store input hexa value in registers
#	$s0: first input
#	$s1: second input
#	$s2: third input
#	$a4: combination of 3 inputs in hexa value e.x: 0xabc
#=================================================
storeInput:
	beq	$k1,1,storeFirstCharacter
	beq	$k1,2,storeSecondCharacter
	beq	$k1,3,storeThirdCharacter
	
	
print:	
	bne	$k1,3, read3ConsecutiveInput
#=============================================================
# wait for Enter or Delete command in the Keyboard MMIO
# Enter: 0xa
# Delete: 0x7f
# BackSpace: 0x8
#=============================================================

waitForKey: 
	lw	$s4, 0($t7)		# $s4 = [$t7] = KEY_READY
	beq 	$s4, $zero, waitForKey	# if $s4 == 0 then keep waiting
	nop
	
	
	
	sw	$zero,0($t7)
	li	$s4,0
	
readKey: 
	lw 	$a2, 0($t6)			# $t0 = [$k0] = KEY_CODE
	
	beq	$a2,0x7f,deleteCode
	beq	$a2,0x8,deleteCode
	
	beq	$a2,0xa,printCommand
	
	j	waitForKey
	
printCommand:	
	li	$v0,34		# print integer (hexa)
	add	$a0,$a1,$zero
	syscall
	nop
	
printNewLine:
	li	$v0,4
	la	$a0,newLine
	syscall

sleep:				# sleep 100ms
	li	$a0,100
	li	$v0,32
	syscall			# continue polling

readNextCharacter:
	j	read3ConsecutiveInput
#back_to_polling: j 	polling


checkFirstRow:	
	li	$t3,0x01
	j 	polling

checkSecondRow:	
	li	$t3,0x02
	j 	polling
	
checkThirdRow:
	li 	$t3,0x04
	j 	polling

checkFourthRow:
	li	$t3,0x08
	j	polling
	
	
storeFirstCharacter:
	add	$s0,$a0,$zero
	sll	$a1,$s0,8	# shift left the first input e.x: 0xa00
	j	print
	
	
	
storeSecondCharacter:
	add	$s1,$a0,$zero
	sll	$t8,$s1,4	# shift left the second input ex. 0xab0
	add	$a1,$a1,$t8
	j	print
	
storeThirdCharacter:
	add	$s2,$a0,$zero
	sll	$t8,$s2,0	# shift left the third input e.x: 0xabf
	add	$a1,$a1,$t8
	j	print

set0:
	li	$a0,0x0
	j 	storeInput

set1:
	li	$a0,0x1
	j 	storeInput	

set2:
	li	$a0,0x2
	j 	storeInput
	
set3: 
	li	$a0,0x3
	j	storeInput
	
set4:
	li	$a0,0x4
	j	storeInput
	
set5:
	li	$a0,0x5
	j 	storeInput
	
set6:
	li	$a0,0x6
	j 	storeInput
	
set7:
	li	$a0,0x7
	j 	storeInput
	
set8:
	li	$a0,0x8
	j 	storeInput
set9:
	li	$a0,0x9
	j 	storeInput
	
setA:
	li	$a0,0xa
	j 	storeInput

setB:
	li	$a0,0xb
	j 	storeInput
	
setC:
	li	$a0,0xc
	j 	storeInput
setD:
	li	$a0,0xd
	j 	storeInput
	
setE:
	li	$a0,0xe
	j 	storeInput
	
setF:
	li	$a0,0xf
	j 	storeInput
	
deleteCode:
	add	$a1,$zero,$zero
	j	reset