.global _start
.equ uart, 0x10000
.equ bufsize, 256
.equ com_max_len, 256
# pointer to command is in t5
# current cell number is in t2

_start:
la sp, _stack

la a0, hello
call print_line

j read_command
finish:
jal finish

read_command:
	addi a2, x0, ':
	call putchar
	addi a2, x0, 32
	call putchar
	la t3, command
read_single_char:
	call readchar
	addi t2, x0, 13
	beq t1, t2, execute_command
	la t2, command
	addi t2, t2, com_max_len
	beq t3, t2, read_single_char
	addi a2, t1, 0
	call putchar
	sb t1, 0(t3)
	addi t3, t3, 1

	j read_single_char
execute_command:
	addi a2, x0, 10
	call putchar
	sb x0, 0(t3)
	la t3, store
	addi t3, t3, bufsize - 1
fill0:
	sb x0, 0(t3)
	addi t3, t3, -1
	la t2, store
	addi t2, t2, -1
	bne t3, t2, fill0

	addi t2, x0, 0
	addi t5, x0, 0
	j process_command

readchar:
	lui t0, uart
rlp:
	lb t1, 5(t0)
	andi t1, t1, 1
	beq t1, x0, rlp

	lb t1, 0(t0)
	ret

putchar:
	lui t0, uart
	sb a2, 0(t0)
	ret

load_byte:
	la t3, store
	add t3, t3, t2
	lb t4, 0(t3)
	ret

load_command:
	la a0, command
	add a0, a0, t5
	lb a0, 0(a0)
	ret

find_corr:
	addi t6, x0, 0
lpm:
	call load_command
	addi t1, x0, '[
	beq a0, t1, lpm_open
	addi t1, x0, ']
	beq a0, t1, lpm_close
	jal lpm_cont
lpm_open:
	add t6, t6, a1
	jal lpm_cont
lpm_close:
	sub t6, t6, a1
lpm_cont:
	beq t6, x0, lpm_end
	add t5, t5, a1
	blt t5, x0, trap
	addi t1, x0, com_max_len
	bge t5, t1, trap
	jal lpm
lpm_end:
	jal next_command

finish_executing:
	addi a2, x0, 10
	call putchar
	j read_command

process_command:
	call load_command
	beq a0, x0, finish_executing
	addi t1, x0, '>
	beq a0, t1, process_next
	addi t1, x0, '<
	beq a0, t1, process_prev
	addi t1, x0, '+
	beq a0, t1, process_inc
	addi t1, x0, '-
	beq a0, t1, process_dec
	addi t1, x0, '.
	beq a0, t1, process_print
	addi t1, x0, '[
	beq a0, t1, process_open
	addi t1, x0, ']
	beq a0, t1, process_close
	addi t1, x0, ',
	beq a0, t1, process_read

	jal next_command

process_next:
	addi t1, x0, bufsize - 1
	beq t1, t2, move_to_first
	addi t2, t2, 1
	jal next_command
move_to_first:
	addi t2, x0, 0
	j next_command
process_prev:
	beq t2, x0, move_to_last
	addi t2, t2, -1
	jal next_command
move_to_last:
	addi t2, x0, bufsize - 1
	j next_command
process_inc:
	call load_byte
	addi t4, t4, 1
	sb t4, 0(t3)
	jal next_command
process_dec:
	call load_byte
	addi t4, t4, -1
	sb t4, 0(t3)
	jal next_command
process_print:
	la t3, store
	add t3, t3, t2
	lb t4, 0(t3)
	addi a2, t4, 0
	call putchar
	jal next_command
process_read:
	call readchar
	la t3, store
	add t3, t3, t2
	sb t1, 0(t3)
	addi a2, t1, 0
	call putchar
	j next_command
process_open:
	call load_byte
	addi a1, x0, 1
	beq t4, x0, find_corr
	jal next_command
process_close:
	call load_byte
	addi a1, x0, -1
	bne t4, x0, find_corr
	j next_command
trap:
	la a0, trap_txt
	call print_line
	j finish_executing

print_line:
	addi t4, ra, 0
pr_line_char:
	lb t1, 0(a0)
	beq t1, x0, finish_print
	addi a2, t1, 0
	call putchar
	addi a0, a0, 1
	j pr_line_char
finish_print:
	addi ra, t4, 0
	ret
# goto next command
next_command:
	addi t5, t5, 1
	jal process_command

.data
hello: .asciz "Hello! This is bare-metal brainf*ck powered system\n"
trap_txt: .asciz "TRAP: Something is broken here!!\n"
too_long: .asciz "Line is too long :(\n"
store: .space bufsize, 0
command: .space com_max_len, 0
