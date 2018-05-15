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
	li	$s0,50
	
	li	$a0,55
	addi	$t0,$s0,10
	subi	$t1,$s0,10
	
	
	slt	$a1,$a0,$t0
	sgt	$a2,$a0,$t1
	and	$a1,$a1,$a2
	
	
	
	
	jal	stop
	jal	turnRight
	jal	saveState
	jal	untrack
	jal	track
	jal	go
	
	
	
	
