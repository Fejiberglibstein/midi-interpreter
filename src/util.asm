
.data
	## Errors
	FileNotFound: .asciiz "Could not open file"
	FileNotRead: .asciiz "Could not read from file"
	NoHeader: .asciiz "There was no header chunk found"


.text
	## Decodes some byte sequence into a number based on
	## http://www.music.mcgill.ca/~ich/classes/mumt306/StandardMIDIfileformat.html#BM1_
	## 
	## $a0: address of the starting byte of the number to be decoded
	## $v0: computed number
decode_var_len:
	# Set the return value to 0 initially
	li $v0 0

	# Fill registers with stuff i need
	li $t0 0   # Byte we're currently reading
	mv $t1 $a0 # Position of the byte we're reading

_loop:
	sll $v0  $v0 7 # Shift the accumulated value by 7 bits

	lbu $t0  0($t1)	# read value at t1 into t0
	addi $t1  $t1 1 # Shift t1 over by one byte for the next time we read

	andi $t2  $t0 0x7F # Ignore the eighth bit of the byte
	add $v0  $v0 $t2   # Add the 7 bits we anded to the result

	andi $t2  $t0 0x8   # Get only the last bit of the byte
	bne $t2 $zero _loop # repeat the loop if we have a 1 at the end


	j $ra


################################################################################


	## Get the length of a chunk from the header
	##
	## $a0: address of the starting byte of the chunk
	## $v0: length of the chunk
read_chunk: 
	# Skip over the 4 bytes for the chunk type and read the 32 bit length of the
	# chunk
	lw $v0 4($a0) 


################################################################################


	## Exit and print out an error
	##
	## $a0: address of null terminated string to exit with
exit_with_error: 


	li $v0 10
	syscall
