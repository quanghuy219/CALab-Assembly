.data
tab: .asciiz "\t"
newLine: .asciiz "\n"
Message: .asciiz "Enter number of rows"
ErrorMsg: .asciiz "Invalid Input"

.text
main:
	li	$v0,51			# read input
	la	$a0,Message       
	syscall
	
	addi	$t0,$a0,1
	
	slt	$t2,$a0,$zero
	nop
	beq	$t2,1,printErrorMsg
	nop
endmain:
#====================================================
# param		$a0: number of rows - n 
# Procedure: 	
# loop:  	
#		for i := 1 to n
# param	 	$s0	 i
# printBlankSpace: 
#		for j := 1 to (n-i)
# param		$s1 	 j
# printNumberInAscendingOrder:
#		for k := 1 to i
# param		 $s2 	 k
# printNumberInDescendingOrder:
#		for k := (i-1) to 1
#=======================================================
	
loop:
	addi	$s0,$s0,1		# i++
	sub	$s3,$t0,$s0		# $s3 = n-i
	li	$s1,0
	li	$s2,0
	beq	$s0,$t0,exit	
	nop
	
printBlankSpace:
	addi	$s1,$s1,1		# j++
	jal 	printTab
	nop
	bne	$s1, $s3, printBlankSpace	# if( j != (n-i) ) 
	nop
	
	subi	$s2,$s2,1
printNumberInAscendingOrder:
	
	addi 	$s2,$s2,1		# k++
	add	$a0,$s2,$zero		# Print current number
	jal	printNumber
	nop
	jal	printTab
	nop
	bne	$s2,$s0,printNumberInAscendingOrder  # if ( k != i )
	nop

printNumberInDescendingOrder:	
	subi	$s2,$s2,1		# k--
	
	li	$k0,-1
	beq	$s2,$k0,printNewLine	# if s2 = 0 endLine
	nop
	add	$a0,$s2,$zero
	jal 	printNumber
	nop
	jal	printTab
	nop
	j	printNumberInDescendingOrder
	
printTab:
	li 	$v0,4
	la	$a0,tab
	syscall
	jr	$ra
	nop
printNewLine:
	li	$v0,4
	la	$a0,newLine
	syscall
	j	loop
	nop

printNumber:
	li	$v0,1
	syscall
	jr	$ra
	nop
	
printErrorMsg:
	li	$v0,55
	la	$a0,ErrorMsg
	syscall
exit:
	li	$v0,10
	syscall
