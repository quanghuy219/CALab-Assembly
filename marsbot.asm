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
	jal 	track		# draw track
	
	addi	$a3,$zero,90	# rotate 90 and start
	
running:
	jal rotate
	jal go
	
	# Sleep
	addi	$v0,$zero,32
	li	$a0,3000
	syscall
	
	jal	untrack
	jal 	track
	
	# turn right for 3 seconds
	jal turnRight
	
	
	# Sleep
	addi	$v0,$zero,32
	li	$a0,3000
	syscall
	
	jal	untrack
	jal 	track
	
	# Stop for 3(s)
	jal 	stop
	
	# Sleep
	addi	$v0,$zero,32
	li	$a0,3000
	syscall
	
	jal	untrack
	jal 	track
	
	
	jal 	go
	nop
	# Turn left for 3 seconds
	jal 	turnLeft
	
	
	# Sleep
	addi	$v0,$zero,32
	li	$a0,3000
	syscall
	
	jal	untrack
	jal 	track
	
	# turn left for 3 secs
	jal 	turnLeft
	jal 	rotate

	# Sleep
	addi	$v0,$zero,32
	li	$a0,3000
	syscall
	
	jal	untrack
	jal 	track
	
	# turn right
	jal	turnRight
	jal 	rotate
	
	# Sleep
	addi	$v0,$zero,32
	li	$a0,3000
	syscall
	
	jal	untrack
	jal 	track
	
	
	jal 	turnRight
	jal 	rotate
endmain:

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