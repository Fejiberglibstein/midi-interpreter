.data
	## Errors
	.globl FileNotFound
	FileNotFound: .asciiz "Could not open file"
	.globl FileNotRead
	FileNotRead: .asciiz "Could not read from file"
	.globl NoHeader
	NoHeader: .asciiz "There was no header chunk found"
	.globl WrongFormat
	WrongFormat: .aciiz "Only multitrack files are supported (format type 1)"

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
