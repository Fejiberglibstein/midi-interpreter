.data
	## Name of the midi file to read from. In the future this should be changed
	## to read from user input for file.
	.globl FileName
	.align 2
	FileName: .asciiz "./examples/mario.mid"

.text
.globl main
main:
	jal parse_midi_file
	li $v0 10
	syscall

