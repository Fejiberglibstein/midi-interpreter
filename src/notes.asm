.data
	## Pointer to the list of notes. This list will be heap allocated by
	## repeatedly calling `sbrk`. Each note is 3 words long. The contents of a
	## note are as follows:
	##	
	##	struct note {
	##		word start_time; // The time that this note started playing
	##		word end_time;   // The time that this note finished playing
	## 		byte channel;
	##		byte key;   
	## 		byte instrument; 
	## 		byte volume;    
	##	}
	.globl NotesArray
	NotesArray: .word 0

	## Store the pointer to the first non-completed note in the song, this will
	## speed up the song so it doesn't have to check every single note
	NotesStartPtr: .word 0

.text

	## Adds a note to the list of notes
	##
	## $a0: The current time
	## $a1: Channel the note is played on
	## $a2: key of the note to play
.globl add_note
add_note:
	addi $sp $sp -4
	sw $s0 0($sp)
	move $s0 $a0

	# Allocate some space to store our note. This space is guaranteed to be next
	# to each other in the heap due to how sbrk works. Therefore, when we
	# allocate space, all the notes we allocate will end up right beside each
	# other, allowing us to create a list of notes.
	li $a0 12 # a0: number of bytes to allocate (3 words for a note = 12 bytes)
	li $v0 9 # 9 is syscall for sbrk
	syscall

	# If NotesArray is NULL (no notes have been allocated yet) we should
	# initialize the array
	lw $t0 NotesArray
	bne $t0 $zero _end_if

	# initialize the array if t0 == zero (NULL)
	sw $v0 NotesArray # v0 is the output we just got from the sbrk syscall

_end_if:
	sll $t0 $s1 1          # Multiply channel num by 2 to align to Channels
	lb $t1 Channels($t0)   # Get the instrument from the channels list
	lb $t2 Channels+1($t0) # Get the volume from the channels list

	# Store all our information on the heap using the pointer we just got from
	# sbrk
	sw $s0 0($v0)  # Store the current time at the first four bytes 
				   # We do NOT store the end time because we don't know it yet
	sb $a1 8($v0)  # Store the channel at the 9th byte
	sb $a2 9($v0)  # Store the key of the note at the 10th byte
	sb $t1 10($v0) # Store the instrument at the 11th byte
	sb $t2 11($v0) # Store the volume at the 12th byte

	lw $s0 0($sp)
	addi $sp $sp 4

	jr $ra

################################################################################

	## Will play a note given the channel and key. This will be called when the
	## channel voice message is `note_off`.
	##
	## $a0: Current time
	## $a1: channel
	## $a2: key
.globl end_note
end_note:
	addi $sp $sp -4
	sw $s0 0($sp)

	lw $t0 NotesArray # t0 is the base address of the array
	addi $t0 $t0 -12 # Subtract 12 from t0 since we add 12 at start of loop

	# put the channel and key inside t1 in the correct byte order,
	# as `0x0000[KEY][CHANNEL]`
	move $t1 $a1   # Store the channel in first byte of t1
	sll $t2 $a2 8  # Shift the key 1 byte over
	or $t1 $t1 $t2 # Combine the 2 registers into one

_note_array_loop:
	addi $t0 $t0 12 # go to the next note in the array

	lw $t2 4($t0) # Get the end time from the note
	bne $t2 $zero _note_array_loop # If the time is not zero, continue

	lhu $t2 8($t0) # Get the channel and key
	bne $t2 $t1 _note_array_loop # If the channel & key dont match, continue

	# If we didn't have to continue in the loop, we know we found the correct
	# note
_found_note:
	sw $a0 4($t0) # Update the end time of the note

	addi $sp $sp 4
	lw $s0 0($sp)
	jr $ra
