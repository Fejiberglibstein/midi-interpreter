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
	## v1: (if non-zero) idk if this will be used
.globl execute_event
execute_event:
	lb $t0 0($a0)

	# If the first byte of the track event is `FF`, then it is a meta event
	li $t1 0xFFFFFFFF
	beq $t0 $t1 meta_event 

	# If the first bit is a 1, then it is a channel event
	li $t1 0x8000000
	and $t0 $t0 $t1 
	bne $t1 $zero midi_channel 

	# else, if the first bit is a 0, it is a controller event
	j midi_controller

meta_event:
	j end

midi_channel:
	j end

midi_controller:
	j end

end:
	jr $ra

