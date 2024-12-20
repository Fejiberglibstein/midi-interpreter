.data
	;; Allocate region for 16 channels. Each channel is 2 bytes, one byte for
	;; instrument, and one byte for volume
	Channels: .space 32 ; 2 bytes * 16 channels

	;; Name of the midi file to read from. In the future this should be changed
	;; to read from user input for file.
	FileName: .asciiz "../examples/test.mid"

	;; All the header chunks for a midi file are 4 bits for the chunk type, 4
	;; bytes for chunk length, and 6 bytes for the header's content.
	;;
	;; All midi header chunks are _always_ 6 bytes
	HeaderChunk: .space 14

.text
.globl main
main:

	; read from file, file descriptor goes into $v0
	jal open_file


	; if file descriptor less than 0, error
	lw $a0  FileNotFound
	blt $a0 $zero exit_with_error

	mv $s7  $v0 ; move file descriptor into s0


	; Read from the file descriptor
	mv $a0  $s7         ; file descriptor
	lw $a1  HeaderChunk ; buffer location
	li $a2  12          ; maximum number of characters to read
	li $v0  14          ; 13 is for opening files
	syscall


	jal parse_header

li $v0 10
syscall

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	;; Open a file for reading, file descriptor will go into $v0
open_file:
	lw $a0  FileName ; filename
	li $a1  0x0      ; flags
	li $a2  0x0      ; mode, 0 for read
	li $v0  13       ; 13 is for opening files
	syscall

	j $ra


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	;; Parses the header chunk of the file. This assumes the header chunk has
	;; been filled with meaningful data by reading from a midi file
parse_header:



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


