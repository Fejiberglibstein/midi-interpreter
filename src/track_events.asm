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

	## Does whatever an event is in the midi file format. Not all track events
	## are currently supported
	##
	## a0: address of the event
	## a1: current time
	## v0: the length of this track event, this is used to offset after reading
	##	   this event
	## v1: Has different effects depending on its value.
	##	- 0x000000: No effect
	##	- 0xFFFFFF: End of track
.globl execute_event
execute_event:

	addi $sp $sp -12
	sw $s0 0($sp)
	sw $s1 4($sp)
	sw $s2 8($sp)

	move $s0 $a0 # s0 is the address of the event
	move $s2 $a1 # s2 is the current time in the midi song

	li $v1 0
	lb $t0 0($s0)

	# If the first byte of the track event is `FF`, then it is a meta event
	li $t1 0xFFFFFFFF
	beq $t0 $t1 meta_event 

	# If the first bit is a 1, then it is a channel event
	li $t1 0x8000000
	and $t0 $t0 $t1
	bne $t1 $zero midi_channel

	# I DONT THINK IT WILL EVER REACH THIS
	# else, if the first bit is a 0, it is a controller event

	lw $a0 BadEvent
	j exit_with_error

meta_event:
	lb $t0 2($s0)  # This is the length of the meta message
	addi $v0 $t0 2 # The total length of the track event is 2 + length we read

	lb $t0 1($s0)   # This is whatever meta event it is
	li $t1 0x2F     # load with 2F (end of track meta event)
	bne $t0 $t1 end # If not 2F, go to end

	# If we have 2F (end of track), we can set v1 accordingly 
	li $v1 0xFFFFFFFF 
	j end

midi_channel:
	lb $t0 0($s0) # Get the header byte of the channel event

	andi $s1 $t0 0x0F # Get the last 4 bits, this is our channel number

	srl $t1 $t0 4     # Shift 4 bits so we have the channel status bits
	andi $t1 $t1 0x07 # Remove the fourth bit from the status bits

	lw $t7 jtable($t1) # Load the label that is the $t1'th element in the jtable
	jr $t7             # Jump to the label we loaded from the jtable

_note_off:
	li $v0 3 # The length of this message is 3 bytes
	j end

_note_on:
	li $v0 3 # The length of this message is 3 bytes

	# Get the half word from the channel list at our channel number.
	#
	# the list of channels consists of 2 bytes, a byte for instrument and a byte
	# for volume. We'll load these two bytes and then use them to add to the end
	# of the note array.
	sll $t0 $s1 1        # Multiply the channel number by 2
	lh $t0 Channels($t0) # Get the half word at channel number

	j end

_ctrl_change:
	li $v0 3 # The length of this message is 3 bytes
	j end

_program_change:
	li $v0 2 # The length of this message is 2 bytes
	j end

_key_pressure:
	li $v0 3 # The length of this message is 3 bytes
	# We can just ignore this message :troll:
	j end

_channel_pressure:
	li $v0 2 # The length of this message is 2 bytes
	# We can just ignore this message :troll:
	j end

_pitch_wheel_change:
	li $v0 3 # The length of this message is 3 bytes
	# We can just ignore this message :troll:
	j end


end:
	lw $s0 0($sp)
	lw $s1 4($sp)
	lw $s2 8($sp)
	addi $sp $sp 12

	jr $ra

