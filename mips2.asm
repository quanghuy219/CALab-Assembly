.text
	li	$a1,90
	li	$a0,360
	
	addi	$a1,$a1,360
	div	$a1,$a0
	mfhi	$v0
	
	
sleep2: 
	addi	$v0,$zero,32
	li	$a0,5000
	syscall
	
	jal UNTRACK
	
	jal TRACK
	

turnLeft:
	subi	$a0,$a0,90
	addi	$a0,$a0,360
	div	$a0,$t1
	mfhi	$a0
	
	jal ROTATE
	
sleep3:
	addi	$v0,$zero,32
	li	$a0,4000
	syscall
	
	jal	UNTRACK
	jal 	TRACK

goLeft:	
	addi	$a0,$zero,270
	jal 	ROTATE
	
sleep4:
	addi	$v0,$zero,32
	li	$a0,7000
	syscall
	
	jal	UNTRACK
	
	jal	TRACK