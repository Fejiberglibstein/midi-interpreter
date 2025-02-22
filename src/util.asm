.text
	## Decodes some byte sequence into a number based on
	## http://www.music.mcgill.ca/~ich/classes/mumt306/StandardMIDIfileformat.html#BM1_
	## 
	## $a0: address of the starting byte of the number to be decoded
	## $v0: computed number
	## $v1: offset from starting byte to final byte
.globl decode_var_len
decode_var_len:
	# Set the return value to 0 initially
	li $v0 0

	# Fill registers with stuff i need
	li $t0 0     # Byte we're currently reading
	move $t1 $a0 # Position of the byte we're reading
	li $v1 0     # i

	# Early return out if the first byte is a 0
	lbu $t0 0($t1)
	bne $t0 $zero _loop
	li $v1 1
	jr $ra

_loop:
	sll $v0 $v0 7 # Shift the accumulated value by 7 bits

	lbu $t0 0($t1) # read value at t1 into t0
	addi $t1 $t1 1 # Shift t1 over by one byte for the next time we read
	addi $v1 $v1 1 # Add one to the total offset

	andi $t2 $t0 0x7F # Ignore the eighth bit of the byte
	add $v0 $v0 $t2   # Add the 7 bits we anded to the result

	andi $t2 $t0 0x80   # Get only the last bit of the byte
	bne $t2 $zero _loop # repeat the loop if we have a 1 at the end

	jr $ra


################################################################################


	## Fixes the endianness of the bytes read from the file
	##
	## Because reading from a file puts the bytes of a word in the wrong
	## endianness, we need to fix it
	##
	## (no a0 because this way we can reuuse parameters that are used for read
	## syscall, minimizing instructions)
	## a1: starting address of what was read from the file
	## a2: amount of bytes we read
.globl fix_file_endianness
fix_file_endianness:
	move $fp $ra
	# We need to align the length of the track to a word, so we should round it
	# up to the nearest 4, e.g. if the length is 13, we should make it 16.
	rem $t0 $a2 4 # length % 4
	li $t1 4
	sub $t0 $t1 $t0 # 4 - (length % 4)
	add $a2 $a2 $t0 # length = length + (4 - (length % 4))

	# Divide the amount of bytes we read by 2 to get the amount of words read
	srl $a2 $a2 2 

	li $t0 0
	move $t1 $a1
_endian_loop:
	lw $a0 0($t1)
	jal reverse_endianness
	sw $v0 0($t1)

	addi $t0 $t0 1
	addi $t1 $t1 4

	bne $t0 $a2 _endian_loop

	jr $fp


	## Reverses the endianness of a word
	##
	## a0: register to reverse the bytes of
reverse_endianness:
	li $v0 0

	li $t9 0xFF000000
	and $t8 $a0 $t9
	srl $t8 $t8 24
	or  $v0 $v0 $t8

	li $t9 0x00FF0000
	and $t8 $a0 $t9
	srl $t8 $t8 8
	or  $v0 $v0 $t8

	li $t9 0x0000FF00
	and $t8 $a0 $t9
	sll $t8 $t8 8
	or  $v0 $v0 $t8

	li $t9 0x000000FF
	and $t8 $a0 $t9
	sll $t8 $t8 24
	or  $v0 $v0 $t8

	jr $ra


################################################################################


	## Returns the index of the lowest number from a list of numbers
	##
	## $a0: Length of the list
	## $a1: Pointer of the first element in the list
	## $v0: index of the lowest number
.globl lowest_num
lowest_num:
	sll $a0 $a0 2 # multiply a0 by 4
	li $v0 0      # v0 is the index of lowest number
	li $t0 0      # t0 is `i`

_num_loop:
	add $t1 $a1 $v0 # t1 = list address + index of lowest number
	lw $t2 0($t1)   # t2 is the value of our current lowest number

	add $t1 $a1 $t0 # t1 = a1 + i
	lw $t3 0($t1)   # t3 is the value of list[i]

	# if list[i] >= list[lowest], go to else, otherwise we set v0 = i
	bge $t3 $t2 _end_if 
	move $v0 $t0 # Set index of lowest num = i

_end_if:

	addi $t0 $t0 4
	bne $t0 $a0 _num_loop

	jr $ra
