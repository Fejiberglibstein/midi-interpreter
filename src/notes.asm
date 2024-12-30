

.text

	## Adds a note to the list of notes
	##
	## $a0: Current time
	## $a1: Channel the note is played on
	## $a2: key of the note to play
.globl add_note
add_note:
