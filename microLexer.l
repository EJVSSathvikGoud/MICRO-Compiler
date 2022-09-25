/*Resources Used:
http://web.mit.edu/gnu/doc/html/flex_1.html
*/

%{
    #include "microParser.h"
    #include <string.h>
%}

DIGIT [0-9]
ID [a-zA-Z][a-zA-Z0-9]*

%option noyywrap

%%

[ \t\n]+ /*whitespace*/

["][^"]*["]     {
                    //printf("STRINGLITERAL: %s\n", yytext);
                    yylval.s = strdup(yytext);
                    return STRINGLITERAL;
                }

{DIGIT}+    {
                //printf("INTLITERAL: %s\n", yytext);
                yylval.s = strdup(yytext);
                return INTLITERAL;
            }

{DIGIT}*"."{DIGIT}+ {
                        //printf("FLOATLITERAL: %s\n", yytext);
                        yylval.s = strdup(yytext);
                        return FLOATLITERAL;
                    }

BEGIN   {
            //printf("BEGIN\n");
            return _BEGIN;
        }

PROGRAM    {
    //printf("PROGRAM\n");
    return PROGRAM;
}

END    {
    //printf("END\n");
    return END;
}

FUNCTION    {
    //printf("FUNCTION\n");
    return FUNCTION;
}

READ    {
    //printf("READ\n");
    return READ;
}

WRITE    {
    //printf("WRITE\n");
    return WRITE;
}

IF    {
    //printf("IF\n");
    return IF;
}

ELSE    {
    //printf("ELSE\n");
    return ELSE;
}

FI    {
    //printf("FI\n");
    return FI;
}

FOR    {
    //printf("FOR\n");
    return FOR;
}

ROF    {
    //printf("ROF\n");
    return ROF;
}

BREAK    {
    //printf("BREAK\n");
    return BREAK;
}

CONTINUE    {
    //printf("CONTINUE\n");
    return CONTINUE;
}

RETURN    {
    //printf("RETURN\n");
    return RETURN;
}

INT    {
    //printf("INT\n");
    yylval.var = strdup(yytext);
    return INT;
}

VOID    {
    //printf("VOID\n");
    return VOID;
}

STRING    {
    //printf("STRING\n");
    return STRING;
}

FLOAT    {
    //printf("FLOAT\n");
    yylval.var = strdup(yytext);
    return FLOAT;
}

{ID}    {
            //printf("IDENTIFIER: %s\n", yytext);
            yylval.s = strdup(yytext);
            return IDENTIFIER;
        }

"-""-"[^\n]*"\n"    {/*COMMENT*/}

":="    {
    //printf("OPERATOR: ASSIGNMENT");
    return ASSIGNMENT;
}

"<="    {
    //printf("OPERATOR: LTE");
    return LTE;
}

">="    {
    //printf("OPERATOR: GTE");
    return GTE;
}

"!="    {
    //printf("OPERATOR: NTE");
    return NTE;
}

"+"|"-"|"*"|"/"|"="|"!"|"("|")"|";"|","|"<"|">"   {
                                                            //printf("OPERATOR: %s\n", yytext);
                                                            return *yytext;
                                                        }

%%
