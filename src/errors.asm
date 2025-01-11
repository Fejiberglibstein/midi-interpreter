.data
	## Errors
	.globl FileNotFound
	.align 2
	FileNotFound: .asciiz "Could not open file"
	.globl FileNotRead
	.align 2
	FileNotRead: .asciiz "Could not read from file"
	.globl NoHeader
	.align 2
	NoHeader: .asciiz "There was no header chunk found"
	.globl WrongFormat
	.align 2
	WrongFormat: .asciiz "Only multitrack files are supported (format type 1)"
	.globl BadTracks
	.align 2
	BadTracks: .asciiz "The midi file is not correctly formatted (wrong number of track)"
	.globl BadEvent
	.align 2
	BadEvent: .asciiz "This should not happen"
	.globl NoSmpte
	.align 2
	NoSmpte: .asciiz "Files with the SMPTE format are not supported"

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
