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
					
					
					
.eqv HEADING	0xffff8010
# Integer: An angle between 0 and 359
# 0 : North (up)
# 90: East (right)
# 180: South (down)
# 270: West (left)
.eqv MOVING	0xffff8050	# Boolean: whether or not to move

.eqv LEAVETRACK	 0xffff8020	# Boolean (0 or non-0):
				# whether or not to leave a track
.eqv WHEREX	0xffff8030	# Integer: Current x-location of MarsBot
.eqv WHEREY	0xffff8040	# Integer: Current y-location of MarsBot


.data 
	newLine: .asciiz "\n"
GO: .asciiz "1B4 - GO\n"
STOP: .asciiz "C68 - STOP\n"
TURNLEFT: .asciiz "444 - TURN LEFT\n"
TURNRIGHT: .asciiz "666 - TURN RIGHT\n"
TRACK: .asciiz "DAD - TRACK\n"
UNTRACK: .asciiz "CBC - UNTRACK\n"
GOBACK: .asciiz "999 - GO BACK\n"
		
.text
main:
	li	$t1, IN_ADDRESS_HEXA_KEYBOARD
	li	$t2, OUT_ADDRESS_HEXA_KEYBOARD
	
	li	$t6,KEY_CODE		# $t6: address of key_code
	li 	$t7,KEY_READY		# $t7: address of key_ready
	
	add	$fp,$sp,$zero
	
	li	$k0,0
#============================================================
# Used registers: t1,t2,t3,t5,t6,t7,t8,k0,k1,a0,a1,a2,a3,s0,s1,s2
#
#=============================================================
	
#======================================================
# GLOBAL VARIABLE
# 	$a1: current control code
#	$a2: keycode of enter or delete
#	$a3: angle of movement of marsbot
#======================================================


#===================================================
# Read 3 consecutive input characters
# params:
#	$k1: order of character
#===================================================   
reset:
	li	$k1,0
	
loop:

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
#	$a1: combination of 3 inputs in hexa value e.x: 0xabc
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
	lw 	$a2, 0($t6)			# $a2 = [$t6] = KEY_CODE
	
	beq	$a2,0x7f,deleteCode
	beq	$a2,0x8,deleteCode
	
	beq	$a2,0xa,printCommand
	
	j	waitForKey
	
printCommand:	
	#li	$v0,34		# print integer (hexa)
	#add	$a0,$a1,$zero
	#syscall
	#nop
	
printNewLine:
	#li	$v0,4
	#la	$a0,newLine
	#syscall
	
implementCommand:
	beq	$a1,0x1b4, implementGo
	beq	$a1,0xc68, implementStop
	beq	$a1,0x444, implementTurnLeft
	beq	$a1,0x666, implementTurnRight
	beq	$a1,0xdad, implementTrack
	beq	$a1,0xcbc, implementUntrack
	beq	$a1,0x999, implementReverse	

sleep:				# sleep 100ms
	li	$a0,300
	li	$v0,32
	syscall			# continue polling

readNextCharacter:
	j	read3ConsecutiveInput
#back_to_polling: j 	polling



#----------------------------------------------------------------
# Accept command and perform action
#----------------------------------------------------------------

implementGo:
	jal	printGo
runGo:	jal	go
	j	loop
	
implementStop:
	jal	printStop
runStop:	
	jal	stop
	j	loop

implementTurnLeft:
	jal	printTurnLeft
runTurnLeft:
	li	$at, LEAVETRACK 
	lb	$t5, 0($at)	# check for tracking
	beqz	$t5,implementTurnLeftUntrack
	j	implementTurnLeftTrack
	
implementTurnLeftUntrack:
	#  bot does not go on straight line when turning
	# fix: stop ----> go
	# store move of bot before turn
	li	$v0,MOVING	# store state before turn. move or stop
	lb	$v1,0($v0)
	jal	stop
	jal 	turnLeft
	jal 	saveState

	beq	$v1,1,runGo	# if bot was moving before turn, then keep going
	j	loop
	
implementTurnLeftTrack:
	li	$v0,MOVING
	lb	$v1,0($v0)
	jal	stop
	jal	untrack
	jal	track
	jal	turnLeft
	jal	saveState
	beq	$v1,1,runGo
	j	loop
	
implementTurnRight:
	jal	printTurnRight
runTurnRight:	
	li	$at, LEAVETRACK 
	lb	$t5, 0($at)	# check for tracking
	beqz	$t5,implementTurnRightUntrack
	j	implementTurnRightTrack

implementTurnRightUntrack:
	li	$v0,MOVING
	lb	$v1,0($v0)
	jal	stop
	jal 	turnRight
	jal	saveState

	beq	$v1,1,runGo
	j	loop
	
implementTurnRightTrack:
	li	$v0,MOVING
	lb	$v1,0($v0)
	jal	stop
	jal	untrack
	jal	track
	jal	turnRight
	jal	saveState
	beq	$v1,1,runGo
	j	loop

implementTrack:
	jal	printTrack
runTrack:
	jal	track
	j	loop

implementUntrack:
	jal	printUntrack
runUntrack:	
	jal	untrack
	j	loop
	
implementReverse:
	jal	printGoBack
runReverse:	
	jal	reverse
	j	loop


		

printGo: 
	li	$v0,4
	la	$a0,GO
	syscall
	nop
	jr	$ra
	
printStop:
	li	$v0,4
	la	$a0,STOP
	syscall
	nop
	jr	$ra
printTurnLeft:
	li	$v0,4
	la	$a0,TURNLEFT
	syscall
	nop
	jr	$ra
printTurnRight:
	li	$v0,4
	la	$a0,TURNRIGHT
	syscall
	nop
	jr	$ra
printTrack:
	li	$v0,4
	la	$a0,TRACK
	syscall
	nop
	jr	$ra
printUntrack:
	li	$v0,4
	la	$a0,UNTRACK
	syscall
	nop
	jr	$ra
printGoBack:
	li	$v0,4
	la	$a0,GOBACK
	syscall
	nop
	jr	$ra
#==============================================================
#-----------------------------------------------------------
# 	Scan four rows of the number pad
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
#------------------------------------------------------------------

#-----------------------------------------------------------------------
#	Store the input number in $a1
# params:
# 	$a1: the number
#-----------------------------------------------------------------------

#---------------------------------------------------------------
#	Store first character in $s0 to the third degit from right to left in $a1 
#---------------------------------------------------------------
storeFirstCharacter:
	add	$s0,$a0,$zero
	sll	$a1,$s0,8	# shift left the first input e.x: 0xa00
	j	print
	
#---------------------------------------------------------------
#	Store second character in $s1 to the second degit from right to left in $a1 
#---------------------------------------------------------------	
	
storeSecondCharacter:
	add	$s1,$a0,$zero
	sll	$t8,$s1,4	# shift left the second input ex. 0xab0
	add	$a1,$a1,$t8
	j	print


#---------------------------------------------------------------
#	Store third character in $s2 to the first degit from right to left in $a1 
#---------------------------------------------------------------	
	
storeThirdCharacter:
	add	$s2,$a0,$zero
	sll	$t8,$s2,0	# shift left the third input e.x: 0xabf
	add	$a1,$a1,$t8
	j	print
#---------------------------------------------------------------------------

#--------------------------------------------------------------------------
#	Convert keycode to correspponding hexa value in $a0
#---------------------------------------------------------------------------
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
	
	
#-------------------------------------------------------
# Delete the command in $a1
#-------------------------------------------------------
deleteCode:
	add	$a1,$zero,$zero
	j	reset
	
	
	



#-----------------------------------------------------------
# GO procedure, to start running
# param[in]	none
#-----------------------------------------------------------

go:
	li	$at, MOVING	# change MOVING port
	addi 	$t5, $zero,1	# to logic 1,
	sb	$t5, 0($at)	# to start running
	
	jr	$ra
	
#-----------------------------------------------------------
# STOP procedure, to stop running
# param[in] none
#-----------------------------------------------------------

stop:
	li	$at, MOVING	# change MOVING port to 0
	sb	$zero, 0($at)	# to stop
	jr	$ra
	
#-----------------------------------------------------------
# TRACK procedure, to start drawing line
# param[in]	none
#-----------------------------------------------------------
track: 
	li	$at, LEAVETRACK # change LEAVETRACK port
	addi 	$t5, $zero,1	# to logic 1,
	sb	$t5, 0($at)	# to start tracking
	jr	$ra
	
#-----------------------------------------------------------
# UNTRACK procedure, to stop drawing line
# param[in]	none
#-----------------------------------------------------------

untrack:
	li	$at, LEAVETRACK # change LEAVETRACK port to 0
	sb	$zero, 0($at)	# to stop drawing tail
	jr 	$ra
	nop
	
#-----------------------------------------------------------
# ROTATE procedure, to rotate the robot
# param[in]	$a1, An angle between 0 and 359
#	0 : North (up)
#	90: East (right)
#	180: South (down)
#	270: West (left)
#-----------------------------------------------------------

rotate: 
	li	$at, HEADING	# change HEADING port
	sw	$a3, 0($at)	# to rotate robot
	jr 	$ra
	nop


#-------------------------------------------------------------
# Turn right procedure, turn 90* right from current direction
# param: 
#	$a1: the angle of motion
#	Subtract a1 = a1 + 90
#	Add a1 = a1 + 360 to remove negetive number
#	Take a1 = a1 % 360 to avoid number greater than 360
#-------------------------------------------------------------
turnRight:
	addi	$a3,$a3,90
	addi	$a3,$a3,360
	li	$t5,360
	div	$a3,$t5
	mfhi	$a3
	
	# Rotate procedure
	li	$at, HEADING	# change HEADING port
	sw	$a3, 0($at)	# to rotate robot
	jr 	$ra
	nop

#-------------------------------------------------------------
# Turn left procedure, turn 90* left from current direction
# param: 
#	$a1: the angle of motion
#	Subtract a1 = a1 - 90
#	Add a1 = a1 + 360 to remove negetive number
#	Take a1 = a1 % 360 to avoid number greater than 360
#-------------------------------------------------------------
turnLeft:
	subi	$a3,$a3,90
	addi	$a3,$a3,360
	li	$t5,360
	div	$a3,$t5
	mfhi	$a3
	# Rotate procedure
	li	$at, HEADING	# change HEADING port
	sw	$a3, 0($at)	# to rotate robot
	jr	$ra
	
#=================================================================
# Use stack to store the reverse of current state in every turn.
#	Structure stored in stack 
#	1 - $t8: reverse angle       angle = (angle + 180) % 360
# 	2 - $t9: X or Y cooridnate at the turn
# 	3 - mark : 0: store x, 1: store y
#=================================================================

saveState:
	addi	$sp,$sp,12	# move head of Stack
	addi	$t8,$a3,180	
	li	$t9,360
	div	$t8,$t9
	mfhi	$t8		# angle
	sw	$t8,-8($sp)	# store reverse angle in stack
	li	$t9,180
	div	$t8,$t9
	mfhi	$t8
	beqz	$t8,saveY	# jump to save Y
	j	saveX		# jump to save X
	
	
saveX:	# store WHEREX in $t6, $t7 = 0
	li	$at,WHEREX
	lw	$t9,0($at)	# save X in stack
	sw	$t9,-4($sp)
	sw	$zero,0($sp)
	jr 	$ra
saveY:	# store WHEREY in $t6, $t7 = 1
	li	$at,WHEREY
	lw	$t9,0($at)	# save Y in stack
	addi	$at,$zero,1	# save 1
	sw	$t9,-4($sp)
	sw	$at,0($sp)
	jr	$ra

#---------------------------------------------------------------
# Reverse the route of marsbot
#	Pop data from stack
#	$t7:	mark of X or Y: 0 - X, 1 - Y
#	$t8: value of X or Y
#	$a3: angle to go back
#---------------------------------------------------------------
	
reverse:
	jal	stop
	beq	$sp,$fp,main	# Origin of the plane, restart the program
	# Revserse
	lw	$t7,0($sp)	# 0 - WHEREX, 1-WHEREY
	lw	$t8,-4($sp)	# X or Y
	lw	$a3,-8($sp)	# angle
	addi	$sp,$sp,-12
	addi	$s6,$t8,5	# set error of 10 for the original position
	subi	$s7,$t8,5	#  (x-5, x+5) or (y-5,y+5)
	jal	rotate
	jal	untrack
	
	jal	go
	
loopBack:	
	jal	stop
	jal	checkConditionXY
	slt	$k0,$a0,$s6	# if  x0 - 10 < x < x0 + 10 => back to the previous turn 
	sgt	$k1,$a0,$s7
	and	$k0,$k0,$k1
	jal	go
	beq	$k0,1,reverse
	j	loopBack	

checkConditionXY:
	beqz	$t7,loadX
	j	loadY
	nop
loadX:
	li	$at,WHEREX
	lw	$a0,0($at)
	jr	$ra
	
loadY:
	li	$at,WHEREY
	lw	$a0,0($at)
	jr	$ra
	
	
