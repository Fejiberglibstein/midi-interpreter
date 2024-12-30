
.data
	## Pointer to the list of notes. This list will be heap allocated by
	## repeatedly calling `sbrk`. Each note is 2 words long. The contents of a
	## note are as follows:
	##	
	##	struct note {
	##		word start; // The millisecond the note started on. 
	## 		byte channel;    // The channel number of the note
	##		byte key;   
	## 		byte instrument; 
	## 		byte volume;    
	##	}
	Notes: .word 0

.text

	## Adds a note to the list of notes
	##
	## $a0: Current time
	## $a1: Channel the note is played on
	## $a2: key of the note to play
.globl add_note
add_note:

