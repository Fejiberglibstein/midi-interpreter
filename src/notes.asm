
.data
	## Pointer to the list of notes. This list will be heap allocated by
	## repeatedly calling `sbrk`. Each note is 1 word long. The contents of a
	## note are as follows:
	##	
	##	struct note {
	## 		byte channel; // The channel number of the note
	##		byte key;   
	## 		byte instrument; 
	## 		byte volume;    
	##	}
	NotesArray: .word 0

.text

	## Adds a note to the list of notes
	##
	## $a0: Channel the note is played on
	## $a1: key of the note to play
.globl add_note
add_note:
	addi $sp $sp -8
	sw $s0 0($sp)
	sw $s1 4($sp)

	move $s0 $a0 # s0 is the channel the note is played on
	move $s1 $a1 # s1 is the key of the note to play

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
	sb $s1 0($v0) # Store the channel at the 5th byte
	sb $s2 1($v0) # Store the key of the note at the 6th byte
	sb $t1 2($v0) # Store the instrument at the 7th byte
	sb $t2 3($v0) # Store the volume at the 7th byte


	lw $s0 0($sp)
	lw $s1 4($sp)
	addi $sp $sp 8

	jr $ra
