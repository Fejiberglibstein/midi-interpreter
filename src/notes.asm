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
	NotesArray: .word 0

.text

	## Adds a note to the list of notes
	##
	## $a0: The current time
	## $a1: Channel the note is played on
	## $a2: key of the note to play
.globl add_note
add_note:

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
	sw $a0 0($v0)  # Store the current time at the first four bytes 
				   # We do NOT store the end time because we don't know it yet
	sb $a1 8($v0)  # Store the channel at the 9th byte
	sb $a2 9($v0)  # Store the key of the note at the 10th byte
	sb $t1 10($v0) # Store the instrument at the 11th byte
	sb $t2 11($v0) # Store the volume at the 12th byte

	jr $ra

################################################################################

	jr $ra
