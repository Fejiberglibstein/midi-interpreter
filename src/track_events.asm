##																			  ##
##                            SUPPORTED TRACK EVENTS                          ##  
##																			  ##
	## Midi channel voice messages
	#
	# All are supported

	## Meta Events
	#
	# All meta events can be parsed, but the majority of them do not have any
	# effect. Only the following have an effect: 
	# - `2F` (end of track)

.data
	## Allocate region for 16 channels. Each channel is 2 bytes, one byte for
	## instrument, and one byte for volume
	.align 2
	.globl Channels
	Channels: .space 32 # 2 bytes * 16 channels


	## Create a jump table for all the different channel messages there are.
	## These are ordered as they are in [this](http://www.music.mcgill.ca/~ich/classes/mumt306/StandardMIDIfileformat.html#BMA1_1)
	.align 2
	jtable: .word _note_off, _note_on, _key_pressure, _ctrl_change, _program_change, _channel_pressure, _pitch_wheel_change
	
.text

################################################################################


	## Executes all 0 length tracks events in a track chunk. Once a track event
	## has a variable length > 0, the procedure returns the variable length
	##
	## a0: Address of the first track in the chunk
	## a1: Current time
	## v0: Variable length value
	## v1: address of the variable length
.globl execute_track_events
execute_track_events:
	# Make room on the stack for $ra, $s0, $s1
	addi $sp $sp -20
	sw $ra 0($sp)
	sw $s0 4($sp)
	sw $s1 8($sp)
	sw $s2 12($sp)
	sw $s3 16($sp)

	li $s0 0     # s0 is i
	li $s1 0     # s1 is where we read the variable length into
	move $s2 $a0 # s2 contains the address of the track we're currently reading
	move $s3 $a1 # s3 contains the current time
_chunk_loop:
	move $a0 $s2 # a0 is the address of the variable length
	jal decode_var_len

	move $s1 $v0       # Put the variable length value into s1

	# if (var_length != 0 && i != 0) means we need to exit the loop. 
	#
	# We need to check if i != 0 because we stop looping on a non-zero
	# variable length so when we iterate over the chunk again later we don't
	# want to stop on the same track event, so we ignore the variable length
	# when i == 0
	sne $t0 $s1 $zero  # var_length != 0
	sne $t1 $s0 $zero  # i != 0
	and $t0 $t0 $t1    # (var_length != 0 && i != 0)
	bne $t0 $zero _end # go to the end if this condition == 1

	add $s2 $s2 $v1 # Add the length of the var. len. to the address we read

	move $a0 $s2 # a0 is the address of the event
	move $a1 $s3 # a1 is the current time
	jal execute_event

	add $s2 $s2 $v0 # Add the length of the event to the address
	addi $s0 $s0 1  # i += 1

	# execute_event returns some values into v0 that do different things. 
	# If v1 == 0xFFFFFFFF, then that means the end of track meta event has been
	# reached
	li $t0 0xFFFFFFFF
	beq $v1 $t0 _end_of_track

	j _chunk_loop

_end:
	# We're returning the last read variable length 
	move $v0 $s1
	move $v1 $s2

	lw $ra 0($sp)
	lw $s0 4($sp)
	lw $s1 8($sp)
	lw $s2 12($sp)
	lw $s3 16($sp)
	addi $sp $sp 20

	jr $ra

_end_of_track:
	# Load s1, the value of our variable length value, to highest possible
	# value.
	li $s1 0x7FFFFFFF 
	j _end

################################################################################


	## Does whatever an event is in the midi file format. Not all track events
	## are currently supported
	##
	## $a0: address of the event
	## $a1: current time
	## $v0: the length of this track event, this is used to offset after reading
	##      this event
	## $v1: Has different effects depending on its value.
	##	- 0x000000: No effect
	##	- 0xFFFFFF: End of track
execute_event:

	addi $sp $sp -12
	sw $s0 0($sp)
	sw $s1 4($sp)
	sw $ra 8($sp)

	move $s0 $a0 # s0 is the address of the event
	move $a0 $a1 # We want the current time to be the first argument

	li $v1 0
	lbu $t0 0($s0)

	# If the first byte of the track event is `FF`, then it is a meta event
	li $t1 0xFF
	beq $t0 $t1 meta_event 

	# If the first bit is a 1, then it is a channel event
	li $t1 0x00000080
	and $t1 $t0 $t1
	bne $t1 $zero midi_channel

	# I DONT THINK IT WILL EVER REACH THIS
	# else, if the first bit is a 0, it is a controller event

	lw $a0 BadEvent
	j exit_with_error

meta_event:
	lbu $t0 2($s0)  # This is the length of the meta message
	addi $v0 $t0 3 # The total length of the track event is 3 + length we read

	lbu $t0 1($s0)   # This is whatever meta event it is
	li $t1 0x2F     # load with 2F (end of track meta event)
	bne $t0 $t1 end # If not 2F, go to end

	# If we have 2F (end of track), we can set v1 accordingly 
	li $v1 0xFFFFFFFF 
	j end

midi_channel:
	lbu $t0 0($s0) # Get the header byte of the channel event

	andi $s1 $t0 0x0F # Get the last 4 bits, this is our channel number

	srl $t1 $t0 4     # Shift 4 bits so we have the channel status bits
	andi $t1 $t1 0x07 # Remove the fourth bit from the status bits
	sll $t1 $t1 2     # Multiply the index by 4 (size of word)

	lw $t7 jtable($t1) # Load the label that is the $t1'th element in the jtable
	jr $t7             # Jump to the label we loaded from the jtable

_note_off: # When a note is released (ended)
	               # a0 is already set, it is the current time
	move $a1 $s1   # a1 is the channel number
	lbu $a2 1($s0) # The second byte of the event is the key for Note Off Event
	jal end_note

	li $v0 3 # The length of this message is 3 bytes
	j end

_note_on:
	# Get the half word from the channel list at our channel number.
	#
	# the list of channels consists of 2 bytes, a byte for instrument and a byte
	# for volume. We'll load these two bytes and then use them to add to the end
	# of the note array.

	               # a0 is already set, it is the current time
	move $a1 $s1   # a1 is the channel number
	lbu $a2 1($s0) # The second byte of the event is the key for `Note On` Event
	jal add_note

	li $v0 3 # The length of this message is 3 bytes
	j end

_ctrl_change:
	li $v0 3 # The length of this message is 3 bytes
	j end

_program_change:
	li $v0 2 # The length of this message is 2 bytes
	j end

_key_pressure:
	# We can just ignore this message :troll:
	li $v0 3 # The length of this message is 3 bytes
	j end

_channel_pressure:
	# We can just ignore this message :troll:
	li $v0 2 # The length of this message is 2 bytes
	j end

_pitch_wheel_change:
	# We can just ignore this message :troll:
	li $v0 3 # The length of this message is 3 bytes
	j end


end:
	lw $s0 0($sp)
	lw $s1 4($sp)
	lw $ra 8($sp)
	addi $sp $sp 12

	jr $ra

