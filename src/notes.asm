
.data
	## Pointer to the list of notes. This list will be heap allocated by
	## repeatedly calling `sbrk`. Each note is 2 words long. The contents of a
	## note are as follows:
	##	
	##	struct note {
	##		word start_time; // The time that this note started playing
	## 		byte channel; // The channel number of the note
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
	li $a0 4 # a0: number of bytes to allocate (1 word for a note = 4 bytes)
	li $v0 9 # 9 is syscall for sbrk
	syscall

	# If NotesArray is NULL (no notes have been allocated yet) we should
	# initialize the array
	lw $t0 NotesArray
	bne $t0 $zero _continue

	# initialize the array if t0 == zero (NULL)
	sw $v0 NotesArray # v0 is the output we just got from the sbrk syscall

_continue:
	sll $t0 $s1 1          # Multiply the channel number by 2
	lb $t1 Channels($t0)   # Get the instrument from the channels list
	lb $t2 Channels+1($t0) # Get the volume from the channels list

	# Store all our information on the heap using the pointer we just got from
	# sbrk
	sw $a0 0($v0) # Store the current time at the first four bytes 
	sb $a1 4($v0) # Store the channel at the 5th byte
	sb $a2 5($v0) # Store the key of the note at the 6th byte
	sb $t1 6($v0) # Store the instrument at the 7th byte
	sb $t2 7($v0) # Store the volume at the 8th byte

	jr $ra

	lw $s0 0($sp)
	lw $s1 4($sp)
	addi $sp $sp 8

	jr $ra
