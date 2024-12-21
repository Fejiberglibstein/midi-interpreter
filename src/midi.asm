.data 
	## All the header chunks for a midi file are 4 bits for the chunk type, 4
	## bytes for chunk length, and 6 bytes for the header's content.
	##
	## All midi header chunks are _always_ 6 bytes
	HeaderChunk: .space 14

	## Allocate region for 16 channels. Each channel is 2 bytes, one byte for
	## instrument, and one byte for volume
	Channels: .space 32 # 2 bytes * 16 channels

.text
.globl parse_midi_file
parse_midi_file:
	# Make room on the stack for the return address
	addi $sp -4
	sw $ra 0($sp)

	# Open a file for reading, file descriptor will go into $v0
	la $a0  FileName # filename
	li $a1  0x0      # flags
	li $a2  0x0      # mode, 0 for read
	li $v0  13       # 13 is for opening files
	syscall


	# if file descriptor less than 0, error
	la $a0  FileNotFound
	blt $v0 $zero exit_with_error

	move $s7  $v0 # move file descriptor into s0


	# Read from the file descriptor
	move $a0  $s7       # file descriptor
	la $a1  HeaderChunk # buffer location
	li $a2  12          # maximum number of characters to read
	li $v0  14          # 14 is for reading files
	syscall

	# Parse the header
	jal validate_header
	move $s1 $v0 # Put the number of tracks returned into s1

	# Allocate room for an array of pointers. This array of pointers will be
	# used to store the addresses of each track chunk.
	#
	# We have `$s0` amount of tracks, each pointer is 4 bytes, so we need to
	# multiply by 4 and then call sbrk to allocate system memory
	sll $a0 $s1 2 # a0: number of bytes to allocate (4 * t0)
	li $v0 9      # 9 is syscall for sbrk
	syscall
	move $s0 $v0 # Move the pointer returned by sbrk into s0



	# Pop the return address off the stack
	lw $ra 0($sp)
	addi $sp $sp 4
	jr $ra


################################################################################


	## Validates that the header chunk is correctly a midi file and ensures that
	## the midi file is format type 1
	##
	## The only supported format type (at the moment) is type one. Any other
	## format type will result in an error.
	##
	## $a0: address of the start of the header (should be first byte in the
	##      file)
	## $v0: number of tracks in the file
validate_header:
	# Make room on the stack for s0
	addi $sp $sp -4
	sw $s0 0($sp)

	move $s0 $a0

	# Make sure first four bytes are MThd
	lw $t0 0($s0)     # Get the 4 byte header from the chunk, this should be `MThd`
	li $t1 0X4D546864 # Load `MThd` into t1
	# if t0 and t1 arent equal, error
	la $a0 NoHeader
	bne $t0 $t1 exit_with_error


	# Make sure the format of the chunk is 1
	lh $t0 8($s0) # Get the format from the chunk, we skipped type and length
	li $t1 1      # Format should be 1
	# if t0 and t1 arent equal, error
	la $a0 WrongFormat
	bne $t0 $t1 exit_with_error

	# Get the `ntrks` part of the header, this is the amount of tracks inside
	# the file
	lh $v0 10($s0) # Get the ntrks from the chunks

	# Reset stack pointer
	lw $s0 0($sp)
	addi $sp $sp 4

	jr $ra

################################################################################
