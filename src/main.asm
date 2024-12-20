
.data
	;; Allocate region for 16 channels. Each channel is 2 bytes, one byte for
	;; instrument, and one byte for volume
	channels: .space 32 ; 2 bytes * 16 channels

.text
.globl main
main:
	li $v0 33
	li $a3 127
	li $a2 1
	li $a1 1000
	li $a0 67
	syscall

li $v0 10
syscall
