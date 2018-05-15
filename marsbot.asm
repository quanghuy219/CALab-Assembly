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


.text
main:
	li	$t5,360
	jal 	untrack		# draw track
	
	addi	$a3,$zero,90	# rotate 90 and start
	li	$t1,270
	
	add	$fp,$sp,$zero
running:

	li	$s0,WHEREX
	li	$s1,WHEREY
	
	jal	track
	
	jal 	rotate
	
	jal	saveState
	
	jal 	go
	
	# Sleep
	addi	$v0,$zero,32
	li	$a0,3000
	syscall
	
	jal 	stop
	jal	turnRight
	
	jal	saveState
	
	jal	untrack
	jal	track
	jal	go
	
	# Sleep
	addi	$v0,$zero,32
	li	$a0,3000
	syscall
	
	jal	stop	
	jal	turnLeft
	
	jal	saveState
	jal	untrack
	jal	track
	jal	go
	
	# Sleep
	addi	$v0,$zero,32
	li	$a0,3000
	syscall
	
	
	jal	stop
	jal	turnRight
	jal	saveState
	jal	untrack
	jal	track
	jal	go
	
	# Sleep
	addi	$v0,$zero,32
	li	$a0,3000
	syscall
	
	
	
reverse:
	jal	stop
	beq	$sp,$fp,main	
	# Revserse
	lw	$t7,0($sp)	# 0 - WHEREX, 1-WHEREY
	lw	$t8,-4($sp)	# X or Y
	lw	$a3,-8($sp)	# angle
	addi	$sp,$sp,-12
	addi	$s6,$t8,10
	subi	$s7,$t8,10
	jal	rotate
	jal	untrack
	
	jal	go
	
loop:	
	jal	stop
	jal	checkConditionXY
	slt	$k0,$a0,$s6
	sgt	$k1,$a0,$s7
	and	$k0,$k0,$k1
	jal	go
	beq	$k0,1,reverse
	j	loop

checkConditionXY:
	beqz	$t7,loadX
	j	loadY
	nop
loadX:
	lw	$a0,0($s0)
	jr	$ra
	
loadY:
	lw	$a0,0($s1)
	jr	$ra
	
	
endmain:

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
	lw	$t9,0($s0)	# save X in stack
	sw	$t9,-4($sp)
	sw	$zero,0($sp)
	jr 	$ra
saveY:	# store WHEREY in $t6, $t7 = 1
	lw	$t9,0($s1)	# save Y in stack
	addi	$at,$zero,1	# save 1
	sw	$t9,-4($sp)
	sw	$at,0($sp)
	jr	$ra
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
