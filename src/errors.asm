.data
	## Errors
	.globl FileNotFound
	.align 4
	FileNotFound: .asciiz "Could not open file"
	.globl FileNotRead
	.align 4
	FileNotRead: .asciiz "Could not read from file"
	.globl NoHeader
	.align 4
	NoHeader: .asciiz "There was no header chunk found"
	.globl WrongFormat
	.align 4
	WrongFormat: .asciiz "Only multitrack files are supported (format type 1)"
	.globl BadTracks
	.align 4
	BadTracks: .asciiz "The midi file is not correctly formatted (wrong number of track)"

.text
	## Exit and print out an error
	##
	## $a0: address of null terminated string to exit with
.globl exit_with_error
exit_with_error: 
	# Print out an error, a0 already has the null terminated string to print out
	li $v0 4 # 4 is printing out a string
	syscall

	# Exit
	li $v0 10
	syscall
