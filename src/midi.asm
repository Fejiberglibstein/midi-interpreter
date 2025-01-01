.data 
	## All the header chunks for a midi file are 4 bits for the chunk type, 4
	## bytes for chunk length, and 6 bytes for the header's content.
	##
	## All midi header chunks are _always_ 6 bytes
	.align 2
	HeaderChunk: .space 14

	## Pointer to the region of memory where we allocated the list of track
	## pointers
	.align 2
	TrackChunks: .word 0

	## Pointer to the region of memory where we allocated the list of delay for
	## each track
	.align 2
	TrackDelays: .word 0


.text
.globl parse_midi_file
parse_midi_file:
	# Make room on the stack for the return address
	addi $sp $sp -4
	sw $ra 0($sp)

	# Open a file for reading, file descriptor will go into $v0
	la $a0 FileName # filename
	li $a1 0x0      # flags
	li $a2 0x0      # mode, 0 for read
	li $v0 13       # 13 is for opening files
	syscall
	move $s7 $v0 # move file descriptor into s7

	# if file descriptor less than 0, error
	la $a0 FileNotFound
	blt $v0 $zero exit_with_error

	# Read from the file descriptor
	move $a0 $s7       # file descriptor
	la $a1 HeaderChunk # buffer location
	li $a2 14          # maximum number of characters to read
	li $v0 14          # 14 is for reading files
	syscall
	jal fix_file_endianness

	# Parse the header
	la $a0 HeaderChunk # Address of the memory spot
	jal validate_header
	move $a0 $v0 # Put the number of tracks returned into a0
	move $a1 $s7 # Put the file descriptor into a1
	jal allocate_tracks
	move $s0 $v0 # Move the pointer returned to s0

	# Iterate over all the tracks

	# TrackChunks is a `***Track` (Three pointers!)
	lw $t0 TrackChunks # Load the pointer to the first track chunk into t0
	lw $a0 0($t0)   # Dereference the pointer, now a0 is the first track in list
	jal execute_track_events

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

	move $s0 $a0 # s0 = address of header

	# Make sure first four bytes are MThd
	lw $t0 0($s0)     # Get the 4 byte header from the chunk
	li $t1 0X4D546864 # Load `MThd` into t1
	# if t0 and t1 arent equal, error
	la $a0 NoHeader
	bne $t0 $t1 exit_with_error

	# Make sure the format of the chunk is 1
	lh $t0 10($s0) # Get the format from the chunk, we skipped type and length
	li $t1 1      # Format should be 1
	# if t0 and t1 arent equal, error
	la $a0 WrongFormat
	bne $t0 $t1 exit_with_error

	# Get the `ntrks` part of the header, this is the amount of tracks inside
	# the file
	lh $v0 8($s0) # Get the ntrks from the chunks

	# Reset stack pointer
	lw $s0 0($sp)
	addi $sp $sp 4

	jr $ra

################################################################################


	## Allocates space for an pointer array. Each pointer in this array will
	## point to where the track data is in memory.
	##
	## !!! The pointers we allocate will go into TrackChunks and TrackDelays
	##
	## $a0: number of tracks we have
	## $a1: file descriptor to read from
allocate_tracks:
	# Allocate space on the stack
	addi $sp $sp -16
	sw $s0 0($sp)
	sw $s1 4($sp)
	sw $s2 8($sp)
	sw $ra 12($sp)

	move $s0 $a0 # move the number of tracks we have into s0
	move $s1 $a1 # move the file descriptor into s1

	# Allocate room for an array of pointers. This array of pointers will be
	# used to store the addresses of each track chunk.
	#
	# We have `$a0` amount of tracks, each pointer is 4 bytes, so we need to
	# multiply by 4 and then call sbrk to allocate system memory
	sll $a0 $a0 2 # a0: number of bytes to allocate (4 * a0)
	li $v0 9      # 9 is syscall for sbrk
	syscall
	move $s2 $v0 # Move the pointer to the allocated space into s2
	sw $v0 TrackChunks

	# We also want to make room for the delay that each track should store
	#
	# This should be the same size as the previous allocation
			 # a0 has the same value as previous allocation call
	li $v0 9 # 9 is syscall for sbrk
	syscall
	sw $v0 TrackDelays


	# Now we can loop through all the track chunks in the file. 
	#
	# A track chunk is made up of
	#	`<chunk type (4 bytes)> <length (4 bytes)> <MTrk event>+`
	# A MTrk event is made up of
	#	`<delta-time (variable length)> <event (length depends on the event)>`
	# 
	# Each track chunk will follow each other, one after another.

	# for (int i = 0;i < ntrks;i++) (i only increments on a track chunk though)
	li $t7 0 # This will be our `i` in the loop, 
_loop: 

	# Read from the file descriptor to get the next chunk's header
	move $a0 $s1       # file descriptor
	la $a1 HeaderChunk # buffer location
	li $a2 8           # maximum number of characters to read
	li $v0 14          # 14 is for reading files
	syscall
	jal fix_file_endianness

	lw $t2 HeaderChunk+4 # Get the length of the chunk into t2
	# Make sure first four bytes are MTrk
	lw $t0 HeaderChunk # Get the 4 byte header from the chunk
	li $t1 0x4D54726B  # Load `MTrk` into t1
	# if t0 and t1 arent equal, branch to this if
	bne $t0 $t1 _not_track

	# Allocate room for this chunk on the heap
	move $a0 $t2 # the number of bytes to allocate
	li $v0 9     # 9 is for sbrk
	syscall
	# Store the pointer we just allocated into the array of pointers we have
	sll $t0 $t7 2 # multiply t7 by 4
	add $t0 $s2 $t0 # Shift the base address of array by i * 4
	sw $v0 0($t0) 

	# Read from the file descriptor to get the chunks data
	move $a0 $s1 # file descriptor
	move $a1 $v0 # buffer location
	move $a2 $t2 # maximum number of characters to read
	li $v0 14    # 14 is for reading files
	syscall
	# jal fix_file_endianness

	addi $t7 $t7 1 # i ++
	bne $t7 $s0 _loop # if i != ntrks, continue

	# Deallocate space on the stack
	lw $s0 0($sp)
	lw $s1 4($sp)
	lw $s2 8($sp)
	lw $ra 12($sp)
	addi $sp $sp 16

	jr $ra

	# Read the memory into null and then continue on the loop. This is only
	# called when a chunk is _not_ a track.
	#
	# I do not think this will work because i dont think you can have the buffer
	# location be null. We will just assume all files don't have chunks that
	# aren't tracks
_not_track:
	# Read from the file descriptor to get the chunk's bad data
	move $a0 $s1   # file descriptor
	move $a1 $zero # buffer location (we're piping it into null)
	move $a2 $t2   # maximum number of characters to read
	li $v0 14      # 14 is for reading files
	syscall

	j _loop


_error:
	la $a0 BadTracks
	bne $t0 $t1 exit_with_error

################################################################################


	## Executes all 0 length tracks events in a track chunk. Once a track event
	## has a variable length > 0, the procedure returns the variable length
	##
	## a0: Address of the first track in the chunk
	## v0: Variable length value
	## v1: address of the variable length
execute_track_events:
	# Make room on the stack for $ra, $s0, $s1
	addi $sp $sp -16
	sw $ra 0($sp)
	sw $s0 4($sp)
	sw $s1 8($sp)
	sw $s2 12($sp)

	li $s0 0     # s0 is i
	li $s1 0     # s1 is where we read the variable length into
	move $s2 $a0 # s2 contains the address of the track we're currently reading
_chunk_loop:
	bne $s1 $zero _end # go to the end if our variable length is not 0

	move $a0 $s2 # a0 is the address of the variable length
	jal decode_var_len
	move $s1 $v0    # Put the variable length value into s1
	add $s2 $s2 $v1 # Add the length of the var. len. to the address we read

	move $a0 $s2 # a0 is the address of the event
	jal execute_event

	add $s2 $s2 $v0 # Add the length of the event to the address

	# execute_event returns some values into v0 that do different things. 
	# If v0 == 0xFFFFFFFF, then that means the end of track meta event has been
	# reached
	li $t0 0xFFFFFFFF
	beq $t0 $t1 _end_of_track

	j _chunk_loop

_end:
	# We're returning the last read variable length 
	move $v0 $s1
	move $v1 $s2

	lw $ra 0($sp)
	lw $s0 4($sp)
	lw $s1 8($sp)
	lw $s2 12($sp)
	addi $sp $sp 16

	jr $ra


	_end_of_track:
	# Load s1, the value of our variable length value, to highest possible
	# value.
	li $s1 0x7FFFFFFF 
	j _end
