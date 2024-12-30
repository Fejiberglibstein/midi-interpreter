
.data

	## The current time elapsed in the song. Used so that we can properly offset
	## how long we need to wait for when we play a note
	CurrentTime: .word 0

	## Pointer to the list of notes. This list will be heap allocated by
	## repeatedly calling `sbrk`. Each note is 2 words long. The contents of a
	## note are as follows:
	##	
	##	struct note {
	##		word start;   // The millisecond the note started on. 
	## 		byte channel; // The channel number of the note
	##		byte key;   
	## 		byte instrument; 
	## 		byte volume;    
	##	}
	NotesArray: .word 0

.text

	## Adds a note to the list of notes
	##
	## $a0: Current time
	## $a1: Channel the note is played on
	## $a2: key of the note to play
.globl add_note
add_note:
	addi $sp $sp -12
	sw $s0 0($sp)
	sw $s1 4($sp)
	sw $s2 8($sp)

	move $s0 $a0 # s0 is our current time in the song
	move $s1 $a1 # s1 is the channel the note is played on
	move $s2 $a2 # a2 is the key of the note to play

	# Allocate some space to store our note. This space is guaranteed to be next
	# to each other in the heap due to how sbrk works. Therefore, when we
	# allocate space, all the notes we allocate will end up right beside each
	# other, allowing us to create a list of notes.
	li $a0 8 # a0: number of bytes to allocate (2 words for a note = 8 bytes)
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
	sw $s0 0($v0) # Store the time at the first word
	sb $s1 4($v0) # Store the channel at the 5th byte
	sb $s2 5($v0) # Store the key of the note at the 6th byte
	sb $t1 6($v0) # Store the instrument at the 7th byte
	sb $t2 7($v0) # Store the volume at the 7th byte


	lw $s0 0($sp)
	lw $s1 4($sp)
	lw $s2 8($sp)
	addi $sp $sp 12

	jr $ra
