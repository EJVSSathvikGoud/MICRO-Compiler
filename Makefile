DEVNAME = "E J V S Sathvik Goud"
DEVEMAIL = "190010017@iitdh.ac.in"
CC = @g++

dev:
	@echo "$(DEVNAME)"
	@echo "$(DEVEMAIL)"

compiler: microParser.y microLexer.l main.c
	@bison -d -o microParser.c microParser.y
	@flex microLexer.l
	$(CC) main.c lex.yy.c microParser.c -o parse

tiny:
	@g++ -o tiny tiny4regs.C

clean:
	@rm -f microParser.c microParser.h *.o lex.yy.c parse*