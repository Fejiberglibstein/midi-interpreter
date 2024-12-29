##																			  ##
##                            SUPPORTED TRACK EVENTS                          ##  
##																			  ##
	## Midi controller messages
	# 
	# 

	## Midi channel voice messages
	#
	# 

	## Meta Events
	#
	# All meta events can be parsed, but the majority of them do not have any
	# effect. Only the following have an effect: 
	# - `2F` (end of track)

.data
	## Allocate region for 16 channels. Each channel is 2 bytes, one byte for
	## instrument, and one byte for volume
	.align 2
	Channels: .space 32 # 2 bytes * 16 channels
	
.text

	## Does whatever an event is in the midi file format. Not all track events
	## are currently supported
	##
	## a0: address of the event
	## v0: offset to move by after reading this track event
	## v1: Has different effects depending on its value.
	##	- 0x000000: No effect
	##	- 0xFFFFFF: End of track
.globl execute_event
execute_event:
	li $v1 0
	lb $t0 0($a0)

	# If the first byte of the track event is `FF`, then it is a meta event
	li $t1 0xFFFFFFFF
	beq $t0 $t1 meta_event 

	# If the first bit is a 1, then it is a channel event
	li $t1 0x8000000
	and $t0 $t0 $t1
	bne $t1 $zero midi_channel

	# I DONT THINK IT WILL EVER REACH THIS
	# else, if the first bit is a 0, it is a controller event

	li $a0 BadEvent
	j exit_with_error

meta_event:
	lb $t0 2($a0)  # This is the length of the event
	addi $v0 $t0 2 # The offset to move in total is 2 + length 

	lb $t0 1($a0)   # This is whatever meta event it is
	li $t1 0x2F     # load with 2F (end of track meta event)
	bne $t0 $t1 end # If not 2F, go to end

	# If we have 2F (end of track), we can set v1 accordingly 
	li $v1 0xFFFFFFFF 
	j end

midi_channel:
	j end

end:
	jr $ra

