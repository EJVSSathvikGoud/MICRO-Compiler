#include <stdio.h>
#include <string.h>
#include "microParser.h"

extern FILE *yyin;

void yyerror(const char *s)
{
    return;
};

int main (int argc, char *argv[])
{
    yyin = fopen(argv[1],"r");
    yyparse();
    return 0;
}