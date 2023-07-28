boot:	boot.o link.lds
	riscv64-unknown-elf-ld -T link.lds -o boot boot.o

boot.o: boot.s
	riscv64-unknown-elf-as -o boot.o boot.s

clean:
	rm -rf boot.s boot.o
