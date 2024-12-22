.text
	## Decodes some byte sequence into a number based on
	## http://www.music.mcgill.ca/~ich/classes/mumt306/StandardMIDIfileformat.html#BM1_
	## 
	## $a0: address of the starting byte of the number to be decoded
	## $v0: computed number
.globl decode_var_len
decode_var_len:
	# Set the return value to 0 initially
	li $v0 0

	# Fill registers with stuff i need
	li $t0 0   # Byte we're currently reading
	move $t1 $a0 # Position of the byte we're reading

_loop:
	sll $v0  $v0 7 # Shift the accumulated value by 7 bits

	lbu $t0  0($t1)	# read value at t1 into t0
	addi $t1  $t1 1 # Shift t1 over by one byte for the next time we read

	andi $t2  $t0 0x7F # Ignore the eighth bit of the byte
	add $v0  $v0 $t2   # Add the 7 bits we anded to the result

	andi $t2  $t0 0x8   # Get only the last bit of the byte
	bne $t2 $zero _loop # repeat the loop if we have a 1 at the end


	jr $ra


################################################################################


	## Fixes the endianness of the bytes read from the file
	##
	## Because reading from a file puts the bytes of a word in the wrong
	## endianness, we need to fix it
	##
	## a0: starting address of what was read from the file
	## a1: amount of bytes we read
.globl fix_file_endianness
fix_file_endianness:
	li $t0 0
	move $t1 $a0
_loop:
	lw $a0 0($t1)
	jal reverse_endianness
	addi $t0 $t0 1
	addi $t1 $t1 4
	bne $t0 $a1 _loop

	jr $ra


	## Reverses the endianness of a word
	##
	## a0: register to reverse the bytes of
reverse_endianness:
	li $v0 0

	li $t9 0xFF000000
	and $t8 $a0 $t9
	srl $t8 $t1 24
	or  $v0 $v0 $t8

	li $t9 0x00FF0000
	and $t8 $a0 $t9
	srl $t8 $t1 8
	or  $v0 $v0 $t8

	li $t9 0x0000FF00
	and $t8 $a0 $t9
	sll $t8 $t1 8
	or  $v0 $v0 $t8

	li $t9 0x000000FF
	and $t8 $a0 $t9
	sll $t8 $t1 24
	or  $v0 $v0 $t8

	jr $ra
