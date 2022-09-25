/*Resources Used:
http://alumni.cs.ucr.edu/~lgao/teaching/calc/calc.y
*/

%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <iostream>
#include <unordered_map>
#include <vector>
#include <stack>

#define AR_SIZE 15
#define DEBUG cout<<"Hello"<<endl;

using namespace std;

void yyerror(const char *s);
int yylex();

struct entry
{
        char *name;
        char *type;
        char *value;
};

struct symbol_table
{
        char *name;
        int num_entries;
        struct entry variable[50];
};

struct CodeObject
{
        int num_entries;
        char *instructions[1000];
        char *vartype;
        char *instruction_type;
        char *result;
        char *label;
        int register_num;
        bool is_register;
};

struct symbol_table table_list[50];
int table_index = -1;
int block_count = 0;
char *current_type;
char *current_scope=NULL;

unordered_map<char *,char *> type_map;
int param_count = 0;
stack <int> arg_count;

int register_count=0;
int label_count = 1;
bool declaring = false;
bool read_write = false;
struct CodeObject *code;

vector<bool> register_status(4,false);

void reset_registers()
{
        for(auto x:register_status)
                x = false;
}

int get_register()
{
        for(int i=0;i<4;i++)
        {
                if(!register_status[i])
                {
                        register_status[i] = true;
                        return i;
                }
        }
        for(int i=0;i < code->num_entries;i++)
                {
                        printf("%s\n", code->instructions[i]);
                }
                printf("end\n");
        cout << "No Free Registers" << endl;
        exit(0);
}

void free_register(int i)
{
        register_status[i]=false;
}

void pushpop_registers(struct CodeObject *code,int pushpop)
{
        for(int i=0;i<4;i++)
        {
                code->instructions[code->num_entries]=(char *)malloc(200*sizeof(char));
                if(pushpop)
                {
                        strcat(code->instructions[code->num_entries],"push ");
                        char *temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"r%d",i);
                        strcat(code->instructions[code->num_entries],temp);
                }
                else
                {
                        strcat(code->instructions[code->num_entries],"pop ");
                        char *temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"r%d",3-i);
                        strcat(code->instructions[code->num_entries],temp);
                }
                code->num_entries++;
        }
}

%}

%token STRINGLITERAL
%token INTLITERAL
%token FLOATLITERAL
%token _BEGIN
%token IDENTIFIER
%token PROGRAM
%token END
%token FUNCTION
%token READ
%token ASSIGNMENT
%token GTE
%token LTE
%token NTE
%token WRITE
%token IF
%token ELSE
%token FI
%token FOR
%token ROF
%token BREAK
%token CONTINUE
%token RETURN
%token INT
%token VOID
%token STRING
%token FLOAT

%type <var_entry> var_decl param_decl id_list id_tail
%type <s_entry> string_decl
%type <var> vartype
%type <code> cond primary expr factor expr_prefix factor_prefix postfix_expr compop addop mulop call_expr expr_list expr_list_tail
%type <s> id str INTLITERAL FLOATLITERAL

%union 
{
        struct entry *var_entry;
        struct entry *s_entry;
        struct CodeObject *code;
        char *var;
        char *s;
}

%%

program: PROGRAM id _BEGIN
        {
                table_index = 0;
                table_list[table_index].name = (char *)"GLOBAL";
                table_list[table_index].num_entries = 0;

                code = (struct CodeObject *)malloc(sizeof(struct CodeObject));
                code->num_entries = 0;
        }
        pgm_body END
        {
                for(int i=0;i < code->num_entries;i++)
                {
                        printf("%s\n", code->instructions[i]);
                }
                printf("end\n");
        }
        ;
id: IDENTIFIER {
                if(!declaring && !read_write)
                {
                        for(int j=0;j<=table_index;j++)
                        {
                                if(current_scope != NULL)
                                {
                                        if(!strcmp(current_scope,table_list[j].name))
                                        {
                                                bool found = false;
                                                int count = 0;
                                                for(int k=j;k<=table_index;k++)
                                                {
                                                        for(int i=0;i < table_list[k].num_entries;i++)
                                                        {
                                                                if(!strcmp($<s>$,table_list[k].variable[i].name))
                                                                {
                                                                        $<s>$ = (char *) malloc(200*sizeof(char));
                                                                        if(count < param_count)
                                                                                strcat($<s>$,"$");
                                                                        else strcat($<s>$,"$-");
                                                                        char *temp = (char *) malloc(200*sizeof(char));
                                                                        if(count < param_count)
                                                                                sprintf(temp,"%d",count+6);
                                                                        else sprintf(temp,"%d",count+1-param_count);
                                                                        strcat($<s>$,temp);
                                                                        type_map[$<s>$]=table_list[j].variable[i].type;
                                                                        found = true;
                                                                        break;
                                                                }
                                                                count++;
                                                        }
                                                        if(found) break;
                                                }
                                        }
                                }
                        }
                }

                if(declaring)
                {
                        if(!table_index)
                        {
                                code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                                char temp[200] = "var ";
                                strcat(temp,$$);
                                strcpy(code->instructions[code->num_entries],temp);
                                code->num_entries++;
                        }
                }
                else if(read_write)
                {
                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries], "sys ");
                        strcat(code->instructions[code->num_entries], code->instruction_type);
                        bool found = false;
                        for(int j=0;j<=table_index;j++)
                        {
                                if(current_scope != NULL)
                                {
                                        if(!strcmp(current_scope,table_list[j].name))
                                        {
                                                bool found_local = false;
                                                int count = 0;
                                                for(int k=j;k<=table_index;k++)
                                                {
                                                        for(int i=0;i < table_list[k].num_entries;i++)
                                                        {
                                                                if(!strcmp($<s>$,table_list[k].variable[i].name))
                                                                {
                                                                        $<s>$ = (char *) malloc(200*sizeof(char));
                                                                        if(count < param_count)
                                                                                strcat($<s>$,"$");
                                                                        else strcat($<s>$,"$-");
                                                                        char *temp = (char *) malloc(200*sizeof(char));
                                                                        if(count < param_count)
                                                                                sprintf(temp,"%d",i+6);
                                                                        else sprintf(temp,"%d",i+1-param_count);
                                                                        strcat($<s>$,temp);
                                                                        if(!strcmp("FLOAT",table_list[k].variable[i].type))
                                                                        {
                                                                                strcat(code->instructions[code->num_entries], "r ");
                                                                        }
                                                                        else if(!strcmp("INT",table_list[k].variable[i].type))
                                                                        {
                                                                                strcat(code->instructions[code->num_entries], "i ");
                                                                        }
                                                                        else if(!strcmp("STRING",table_list[k].variable[i].type))
                                                                        {
                                                                                strcat(code->instructions[code->num_entries], "s ");
                                                                        }
                                                                        found = true;
                                                                        found_local = true;
                                                                        break;
                                                                }
                                                                count++;
                                                                if(found_local)
                                                                        break;
                                                        }
                                                }
                                        }
                                }
                        }
                        if(!found)
                        {
                                for(int i=0;i < table_list[0].num_entries;i++)
                                {
                                        if(!strcmp($<s>$,table_list[0].variable[i].name))
                                        {
                                                if(!strcmp("FLOAT",table_list[0].variable[i].type))
                                                {
                                                        strcat(code->instructions[code->num_entries], "r ");
                                                }
                                                else if(!strcmp("INT",table_list[0].variable[i].type))
                                                {
                                                        strcat(code->instructions[code->num_entries], "i ");
                                                }
                                                else if(!strcmp("STRING",table_list[0].variable[i].type))
                                                {
                                                        strcat(code->instructions[code->num_entries], "s ");
                                                }
                                                found = true;
                                                break;
                                        }
                                }
                        }
                        strcat(code->instructions[code->num_entries],$$);
                        code->num_entries++;
                }
        }
        ;
pgm_body: decl
        {
                code->instructions[code->num_entries]=(char *)malloc(200*sizeof(char));
                strcat(code->instructions[code->num_entries],"push");
                code->num_entries++;
                pushpop_registers(code,1);

                code->instructions[code->num_entries]=(char *)malloc(200*sizeof(char));
                strcat(code->instructions[code->num_entries],"jsr main");
                code->num_entries++;

                code->instructions[code->num_entries]=(char *)malloc(200*sizeof(char));
                strcat(code->instructions[code->num_entries],"sys halt");
                code->num_entries++;

        } func_declarations
        ;
decl: string_decl decl | var_decl decl |
        ;

string_decl: STRING id ASSIGNMENT str ';'
                {
                        struct symbol_table *current = &table_list[table_index];

                        $$ = (struct entry*)malloc(sizeof(struct entry));
                        $$->name = strdup($2);
                        $$->type = (char *)"STRING";
                        $$->value = $4;
                        current->variable[current->num_entries] = *($$);
                        current->num_entries++;

                        for(int j=0;j<=table_index;j++)
                        {
                                if(current_scope != NULL)
                                {
                                        if(!strcmp(current_scope,table_list[j].name))
                                        {
                                                bool found = false;
                                                int count = 0;
                                                for(int k=j;k<=table_index;k++)
                                                {
                                                        for(int i=0;i < table_list[k].num_entries;i++)
                                                        {
                                                                if(!strcmp($2,table_list[k].variable[i].name))
                                                                {
                                                                        $2 = (char *) malloc(200*sizeof(char));
                                                                        if(count < param_count)
                                                                                strcat($2,"$");
                                                                        else strcat($2,"$-");
                                                                        char *temp = (char *) malloc(200*sizeof(char));
                                                                        if(count < param_count)
                                                                                sprintf(temp,"%d",count+6);
                                                                        else sprintf(temp,"%d",count+1-param_count);
                                                                        strcat($2,temp);
                                                                        type_map[$2]=table_list[j].variable[i].type;
                                                                        found = true;
                                                                        break;
                                                                }
                                                                count++;
                                                        }
                                                        if(found) break;
                                                }
                                        }
                                }
                        }

                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries], "str "); 
                        strcat(code->instructions[code->num_entries], $2); 
                        strcat(code->instructions[code->num_entries], " "); 
                        strcat(code->instructions[code->num_entries], $4);
                        code->num_entries++;
                }
        ;
str: STRINGLITERAL {}
        ;

var_decl: vartype
                {
                        declaring = true;
                        current_type = $1;

                        code->vartype = $1;
                        code->instruction_type = (char *)malloc(200*sizeof(char));       
                }       
        id_list ';'
        {declaring = false;
        code->instruction_type = NULL;}
        ;
vartype: FLOAT{} | INT{}
        ;
any_type: vartype | VOID
        ;
id_list: id
                {
                        if(declaring)
                        {
                                struct symbol_table *current = &table_list[table_index];

                                $<var_entry>$ = (struct entry*)malloc(sizeof(struct entry));   
                                $<var_entry>$->name = $1;
                                $<var_entry>$->type = current_type;
                                $<var_entry>$->value = NULL;
                                current->variable[current->num_entries] = *($<var_entry>$);
                                current->num_entries++;
                        }
                }
        id_tail {}
        ;
id_tail: ',' id
                {
                        if(declaring)
                        {
                                struct symbol_table *current = &table_list[table_index];

                                $<var_entry>$ = (struct entry*)malloc(sizeof(struct entry));
                                $<var_entry>$->name = $2;
                                $<var_entry>$->type = current_type;
                                $<var_entry>$->value = NULL;
                                current->variable[current->num_entries] = *($<var_entry>$);
                                current->num_entries++;
                        }
                        
                }
        id_tail {}| {}
        ;

param_decl_list: param_decl param_decl_tail |
        ;
param_decl: vartype id
                {
                        struct symbol_table *current = &table_list[table_index];

                        $$ = (struct entry*)malloc(sizeof(struct entry));
                        $$->name = $2;
                        $$->type = $1;
                        $$->value = NULL;
                        current->variable[current->num_entries] = *($$);
                        current->num_entries++;
                        param_count++;
                }
        ;
param_decl_tail: ',' param_decl param_decl_tail |
        ;

func_declarations: func_decl func_declarations |
        ;
func_decl: FUNCTION any_type id
                        {
                                table_index++;
                                table_list[table_index].name = $3;
                                table_list[table_index].num_entries = 0;
                                current_scope = (char *)malloc(200*sizeof(char));
                                strcat(current_scope,$3);
                                param_count=0;
                                
                                code->instructions[code->num_entries]=(char *)malloc(200*sizeof(char));
                                sprintf(code->instructions[code->num_entries],"label %s",$3);
                                code->num_entries++;
                                
                                code->instructions[code->num_entries]=(char *)malloc(200*sizeof(char));
                                sprintf(code->instructions[code->num_entries],"link %d",AR_SIZE);
                                code->num_entries++;

                                reset_registers();
                        }
'(' param_decl_list ')' _BEGIN func_body END
                {
                        current_scope=NULL;
                        param_count=0;
                }
        ;
func_body: decl stmt_list
        ;

stmt_list: stmt stmt_list |
        ;
stmt: base_stmt | if_stmt | for_stmt
        ;
base_stmt: assign_stmt | read_stmt | write_stmt | return_stmt
        ;

assign_stmt: assign_expr ';'
        ;
assign_expr: id ASSIGNMENT expr
                {
                        for(int i=0; i < $3->num_entries;i++)
                        {
                                code->instructions[code->num_entries+i] = $3->instructions[i];
                        }
                        code->num_entries += $3->num_entries;
                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries], "move ");
                        char *temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"r%d",$3->register_num);
                        strcat(code->instructions[code->num_entries], temp);
                        strcat(code->instructions[code->num_entries], " ");
                        strcat(code->instructions[code->num_entries],$1);
                        free_register($3->register_num);
                        code->num_entries++;
                }
        ;
read_stmt: READ 
                {
                        read_write = true;
                        code->instruction_type = (char *)malloc(200*sizeof(char));
                        strcat(code->instruction_type,"read");
                }

        '(' id_list ')' ';'
                {
                        code->instruction_type = NULL;
                        read_write = false;
                }
        ;
write_stmt: WRITE
                {
                        read_write = true;
                        code->instruction_type = (char *)malloc(200*sizeof(char));
                        strcat(code->instruction_type,"write");
                }

        '(' id_list ')' ';'
                {
                        code->instruction_type = NULL;
                        read_write = false;
                }
        ;
return_stmt: RETURN expr ';'
                {
                        for(int i=0;i < $2->num_entries;i++)
                        {
                                code->instructions[code->num_entries+i] = $2->instructions[i];
                        }
                        code->num_entries += $2->num_entries;
                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries], "move ");
                        char *temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"r%d",$2->register_num);
                        strcat(code->instructions[code->num_entries], temp);
                        strcat(code->instructions[code->num_entries], " ");
                        temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"$%d",param_count+6);
                        strcat(code->instructions[code->num_entries],temp);
                        code->num_entries++;

                        free_register($2->register_num);

                        code->instructions[code->num_entries]=(char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries],"unlnk");
                        code->num_entries++;
                        
                        code->instructions[code->num_entries]=(char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries],"ret");
                        code->num_entries++;
                }
        ;

expr: expr_prefix factor
        {       
                if($1 == NULL)
                {
                        $$ = $2;
                }
                else
                {
                        $$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));
                        $$->num_entries = 0;
                        $$->instruction_type = $1->instruction_type;
                        $$->register_num = $1->register_num;
                        $$->vartype = $1->vartype;
                        
                        for(int i=0;i<$1->num_entries;i++)
                        {
                                $$->instructions[i+$$->num_entries] = $1->instructions[i];
                        }
                        $$->num_entries+=$1->num_entries;

                        for(int i=0;i<$2->num_entries;i++)
                        {
                                $$->instructions[i+$$->num_entries] = $2->instructions[i];
                        }
                        $$->num_entries+=$2->num_entries;
                        
                        $$->instructions[$$->num_entries] = (char *)malloc(200*sizeof(char));
                        
                        strcat($$->instructions[$$->num_entries],$$->instruction_type);
                        if(!strcmp("FLOAT",$$->vartype))
                        {
                                strcat($$->instructions[$$->num_entries], "r ");
                        }
                        else if(!strcmp("INT",$$->vartype))
                        {
                                strcat($$->instructions[$$->num_entries], "i ");
                        }
                        char *temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"r%d",$2->register_num);
                        strcat($$->instructions[$$->num_entries],temp);
                        strcat($$->instructions[$$->num_entries]," ");
                        temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"r%d",$$->register_num);
                        strcat($$->instructions[$$->num_entries],temp);
                        free_register($2->register_num);
                        $$->num_entries++;
                }
        }
        ;
expr_prefix: expr_prefix factor addop
        {
                if($1 == NULL)
                {
                        $$ = $2;
                        $$->instruction_type = $3->instruction_type;
                }
                else
                {
                        $$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));
                        $$->num_entries = 0;
                        $$->instruction_type = $1->instruction_type;
                        $$->register_num = $1->register_num;
                        $$->vartype = $1->vartype;

                        for(int i=0;i<$1->num_entries;i++)
                        {
                                $$->instructions[i+$$->num_entries] = $1->instructions[i];
                        }
                        $$->num_entries+=$1->num_entries;

                        for(int i=0;i<$2->num_entries;i++)
                        {
                                $$->instructions[i+$$->num_entries] = $2->instructions[i];
                        }
                        $$->num_entries+=$2->num_entries;
                        

                        $$->instructions[$$->num_entries] = (char *)malloc(200*sizeof(char));

                        strcat($$->instructions[$$->num_entries],$$->instruction_type);
                        if(!strcmp("FLOAT",$$->vartype))
                        {
                                strcat($$->instructions[$$->num_entries], "r ");
                        }
                        else if(!strcmp("INT",$$->vartype))
                        {
                                strcat($$->instructions[$$->num_entries], "i ");
                        }
                        char *temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"r%d",$2->register_num);
                        strcat($$->instructions[$$->num_entries],temp);
                        strcat($$->instructions[$$->num_entries]," ");
                        temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"r%d",$$->register_num);
                        strcat($$->instructions[$$->num_entries],temp);
                        free_register($2->register_num);
                        $$->instruction_type = $3->instruction_type;
                        $$->num_entries++;
                }
        }
        | {$$ = NULL;}
        ;
factor: factor_prefix postfix_expr
        {
                if($1 == NULL)
                {
                        $$ = $2;
                }
                else
                {
                        $$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));
                        $$->num_entries = 0;
                        $$->instruction_type = $1->instruction_type;
                        $$->register_num = $1->register_num;
                        $$->vartype = $1->vartype;

                        for(int i=0;i<$1->num_entries;i++)
                        {
                                $$->instructions[i+$$->num_entries] = $1->instructions[i];
                        }
                        $$->num_entries+=$1->num_entries;

                        for(int i=0;i<$2->num_entries;i++)
                        {
                                $$->instructions[i+$$->num_entries] = $2->instructions[i];
                        }
                        $$->num_entries+=$2->num_entries;


                        $$->instructions[$$->num_entries] = (char *)malloc(200*sizeof(char));

                        strcat($$->instructions[$$->num_entries],$$->instruction_type);
                        if(!strcmp("FLOAT",$$->vartype))
                        {
                                strcat($$->instructions[$$->num_entries], "r ");
                        }
                        else if(!strcmp("INT",$$->vartype))
                        {
                                strcat($$->instructions[$$->num_entries], "i ");
                        }
                        char *temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"r%d",$2->register_num);
                        strcat($$->instructions[$$->num_entries],temp);
                        strcat($$->instructions[$$->num_entries]," ");
                        temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"r%d",$$->register_num);
                        strcat($$->instructions[$$->num_entries],temp);
                        free_register($2->register_num);
                        $$->num_entries++;
                }
        }
        ;
factor_prefix: factor_prefix postfix_expr mulop
        {
                if($1 == NULL)
                {
                        $$ = $2;
                        $$->instruction_type = $3->instruction_type;
                }
                else
                {
                        $$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));
                        $$->num_entries = 0;
                        $$->instruction_type = $1->instruction_type;
                        $$->register_num = $1->register_num;
                        $$->vartype = $1->vartype;

                        for(int i=0;i<$1->num_entries;i++)
                        {
                                $$->instructions[i+$$->num_entries] = $1->instructions[i];
                        }
                        $$->num_entries+=$1->num_entries;

                        for(int i=0;i<$2->num_entries;i++)
                        {
                                $$->instructions[i+$$->num_entries] = $2->instructions[i];
                        }
                        $$->num_entries+=$2->num_entries;

                        $$->instructions[$$->num_entries] = (char *)malloc(200*sizeof(char));

                        strcat($$->instructions[$$->num_entries],$$->instruction_type);
                        if(!strcmp("FLOAT",$$->vartype))
                        {
                                strcat($$->instructions[$$->num_entries], "r ");
                        }
                        else if(!strcmp("INT",$$->vartype))
                        {
                                strcat($$->instructions[$$->num_entries], "i ");
                        }
                        char *temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"r%d",$2->register_num);
                        strcat($$->instructions[$$->num_entries],temp);
                        strcat($$->instructions[$$->num_entries]," ");
                        temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"r%d",$$->register_num);
                        strcat($$->instructions[$$->num_entries],temp);
                        free_register($2->register_num);
                        
                        $$->instruction_type = $3->instruction_type;
                        $$->num_entries++;
                }
        }

        | {$$ = NULL;} 
        ;
postfix_expr: primary {$$ = $1;} | call_expr {$$ = $1;}
        ;
call_expr: id{arg_count.push(0);} '(' expr_list ')'
        {
                $$ = (struct CodeObject *)malloc(sizeof(CodeObject));
                $$->num_entries = 0;
                $$->instructions[$$->num_entries] = (char *)malloc(200*sizeof(char));
                strcat($$->instructions[$$->num_entries],"push");
                $$->num_entries++;

                if($4 != NULL)
                {
                        for(int i=0;i<$4->num_entries;i++)
                        {
                                $$->instructions[$$->num_entries+i]=$4->instructions[i];
                        }
                        $$->num_entries+=$4->num_entries;
                }
                

                pushpop_registers($$,1);

                $$->instructions[$$->num_entries] = (char *)malloc(200*sizeof(char));
                strcat($$->instructions[$$->num_entries],"jsr ");
                strcat($$->instructions[$$->num_entries],$1);
                $$->num_entries++;

                pushpop_registers($$,0);

                for(int i=0;i<arg_count.top();i++)
                {
                        $$->instructions[$$->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat($$->instructions[$$->num_entries],"pop");
                        $$->num_entries++;
                }

                $$->instructions[$$->num_entries] = (char *)malloc(200*sizeof(char));
                strcat($$->instructions[$$->num_entries],"pop ");
                $$->register_num = get_register();
                char *temp = (char *)malloc(200*sizeof(char));
                sprintf(temp,"r%d", $$->register_num);
                strcat($$->instructions[$$->num_entries],temp);
                $$->num_entries++;

                arg_count.pop();
        }
        ;
expr_list: expr expr_list_tail 
        {
                arg_count.top()++;
                if($2 == NULL)
                        $$ = $1;
                else
                {
                        $$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));
                        $$->num_entries=0;
                        for(int i=0;i<$2->num_entries;i++)
                        {
                                $$->instructions[i]=$2->instructions[i];
                        }
                        $$->num_entries+=$2->num_entries;

                        for(int i=0;i<$1->num_entries;i++)
                        {
                                $$->instructions[$$->num_entries+i]=$1->instructions[i];
                        }
                        $$->num_entries+=$1->num_entries;
                }
                $$->instructions[$$->num_entries] = (char *)malloc(200*sizeof(char));
                strcat($$->instructions[$$->num_entries],"push ");
                char *temp = (char *)malloc(200*sizeof(char));
                sprintf(temp,"r%d",$1->register_num);
                strcat($$->instructions[$$->num_entries],temp);
                free_register($1->register_num);
                $$->num_entries++;
        }
        | {$$ = NULL;}
        ;
expr_list_tail: ',' expr {arg_count.top()++;} expr_list_tail
        {
                if($4 == NULL)
                        $$ = $2;
                else
                {
                        $$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));
                        $$->num_entries=0;
                        for(int i=0;i<$4->num_entries;i++)
                        {
                                $$->instructions[i]=$4->instructions[i];
                        }
                        $$->num_entries+=$4->num_entries;

                        for(int i=0;i<$2->num_entries;i++)
                        {
                                $$->instructions[$$->num_entries+i]=$2->instructions[i];
                        }
                        $$->num_entries+=$2->num_entries;
                }
                $$->instructions[$$->num_entries] = (char *)malloc(200*sizeof(char));
                strcat($$->instructions[$$->num_entries],"push ");
                char *temp = (char *)malloc(200*sizeof(char));
                sprintf(temp,"r%d",$2->register_num);
                strcat($$->instructions[$$->num_entries],temp);
                $$->num_entries++;
        }| {$$ = NULL;}
        ;
primary: '(' expr ')'{$$ = $2;} | id 
        {
                $$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));
                $$->num_entries = 0;
                $$->instructions[$$->num_entries] = (char *)malloc(200*sizeof(char));
                strcat($$->instructions[$$->num_entries],"move ");
                strcat($$->instructions[$$->num_entries],$1);
                strcat($$->instructions[$$->num_entries]," ");
                $$->register_num = get_register();
                char *temp = (char *)malloc(200*sizeof(char));
                sprintf(temp,"r%d", $$->register_num);
                strcat($$->instructions[$$->num_entries],temp);
                $$->num_entries++;
                
                bool found = false;
                for(int i=0;i < table_list[table_index].num_entries;i++)
                {
                        if(!strcmp($1,table_list[table_index].variable[i].name))
                        {
                                $$->vartype = (char *)malloc(200*sizeof(char));
                                strcat($$->vartype,table_list[table_index].variable[i].type);
                        }
                }
                if(!found)
                {
                        for(int i=0;i < table_list[0].num_entries;i++)
                        {
                                if(!strcmp($1,table_list[0].variable[i].name))
                                {
                                        $$->vartype = (char *)malloc(200*sizeof(char));
                                        strcat($$->vartype,table_list[0].variable[i].type);
                                        found=true;
                                        break;
                                }
                        }
                }
                if(!found)
                {
                        $$->vartype = (char *)malloc(200*sizeof(char));
                        strcat($$->vartype,type_map[$1]);
                }
        } |

        INTLITERAL 
        {
                $$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));
                $$->num_entries = 0;
                $$->instructions[$$->num_entries] = (char *)malloc(200*sizeof(char));
                strcat($$->instructions[$$->num_entries],"move ");
                strcat($$->instructions[$$->num_entries],$1);
                strcat($$->instructions[$$->num_entries]," ");
                $$->register_num = get_register();
                char *temp = (char *)malloc(200*sizeof(char));
                sprintf(temp,"r%d", $$->register_num);
                strcat($$->instructions[$$->num_entries],temp);
                $$->vartype = (char *)"INT";
                $$->num_entries++;
        }
        | FLOATLITERAL
        {
                $$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));
                $$->num_entries = 0;
                $$->instructions[$$->num_entries] = (char *)malloc(200*sizeof(char));
                strcat($$->instructions[$$->num_entries],"move ");
                strcat($$->instructions[$$->num_entries],$1);
                strcat($$->instructions[$$->num_entries]," ");
                $$->register_num = get_register();
                char *temp = (char *)malloc(200*sizeof(char));
                sprintf(temp,"r%d", $$->register_num);
                strcat($$->instructions[$$->num_entries],temp);
                $$->vartype = (char *)"FLOAT";
                $$->num_entries++;
        }
        ;
addop: '+'
        {
                $$=(struct CodeObject *)malloc(sizeof(struct CodeObject));
                $$->num_entries = 0;
                $$->instruction_type = (char *)malloc(200*sizeof(char));
                strcat($$->instruction_type,"add");
        }
         | '-'
        {
        	$$=(struct CodeObject *)malloc(sizeof(struct CodeObject));
                $$->num_entries = 0;
                $$->instruction_type = (char *)malloc(200*sizeof(char));
                strcat($$->instruction_type,"sub");
	}
        ;
mulop: '*'
        {
                $$=(struct CodeObject *)malloc(sizeof(struct CodeObject));
                $$->num_entries = 0;
                $$->instruction_type = (char *)malloc(200*sizeof(char));
                strcat($$->instruction_type,"mul");
        } | '/'
        {
        	$$=(struct CodeObject *)malloc(sizeof(struct CodeObject));
                $$->num_entries = 0;
                $$->instruction_type = (char *)malloc(200*sizeof(char));
                strcat($$->instruction_type,"div");                
        }
        ;

if_stmt: IF '(' cond ')' 
                {
                                                
                        table_index++;
                        block_count++;
                        char str[30];
                        sprintf(str,"BLOCK %d", block_count);
                        table_list[table_index].name = strdup(str);
                        table_list[table_index].num_entries = 0;
                        for(int i=0; i < $3->num_entries;i++)
                        {
                                code->instructions[code->num_entries+i] = $3->instructions[i];
                        }
                        code->num_entries += $3->num_entries;
                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries],$3->instruction_type);
                        strcat(code->instructions[code->num_entries], " label");
                        char *temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"%d", label_count);
                        $3->label = temp;
                        strcat(code->instructions[code->num_entries],$3->label);
                        code->num_entries++;
                        label_count++;

                        label_count++;
                }
        decl stmt_list
        {       
                int jump = atoi($3->label);
                jump++;
                char *temp = (char *)malloc(200*sizeof(char));
                sprintf(temp,"%d",jump);
                code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                strcat(code->instructions[code->num_entries], "jmp label");
                strcat(code->instructions[code->num_entries], temp);
                code->num_entries++;

                code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                strcat(code->instructions[code->num_entries], "label label");
                strcat(code->instructions[code->num_entries],$3->label);
                $3->label=temp;
                code->num_entries++;
        }
        else_part FI
        {
                code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                strcat(code->instructions[code->num_entries], "label label");
                strcat(code->instructions[code->num_entries],$3->label);
                code->num_entries++;
        }
        ;
else_part: ELSE
                {                        
                        table_index++;
                        block_count++;
                        char str[30];
                        sprintf(str,"BLOCK %d", block_count);
                        table_list[table_index].name = strdup(str);
                        table_list[table_index].num_entries = 0;
                }
        decl stmt_list
        |
        ;
cond: expr compop expr
        {
                $2->num_entries = 0;
                for(int i=0; i < $1->num_entries;i++)
                {
                        $2->instructions[$2->num_entries+i] = $1->instructions[i];
                }
                $2->num_entries += $1->num_entries;

                for(int i=0; i < $3->num_entries;i++)
                {
                        $2->instructions[$2->num_entries+i] = $3->instructions[i];
                }
                $2->num_entries += $3->num_entries;
                
                $2->instructions[$2->num_entries] = (char *)malloc(200*sizeof(char));
                strcat($2->instructions[$2->num_entries],"cmp");
                if(!strcmp("FLOAT",$1->vartype))
                {
                        strcat($2->instructions[$2->num_entries], "r ");
                }
                else if(!strcmp("INT",$1->vartype))
                {
                        strcat($2->instructions[$2->num_entries], "i ");
                }
                char *temp=(char *)malloc(200*sizeof(char));
                sprintf(temp,"r%d",$1->register_num);
                strcat($2->instructions[$2->num_entries],temp);
                strcat($2->instructions[$2->num_entries]," ");
                temp=(char *)malloc(200*sizeof(char));
                sprintf(temp,"r%d",$3->register_num);
                strcat($2->instructions[$2->num_entries],temp);
                free_register($1->register_num);
                free_register($3->register_num);
                $2->num_entries++;
                $$ = $2;
        }
        ;
compop: '<'{$$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));$$->instruction_type = (char *)"jge";} | '>'{$$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));$$->instruction_type = (char *)"jle";} | '='{$$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));$$->instruction_type = (char *)"jne";} | NTE{$$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));$$->instruction_type = (char *)"jeq";} | LTE{$$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));$$->instruction_type = (char *)"jgt";} | GTE{$$ = (struct CodeObject *)malloc(sizeof(struct CodeObject));$$->instruction_type = (char *)"jlt";}
        ;
init_stmt: assign_expr |
        ;
incr_stmt: assign_expr |
        ;
for_stmt: FOR
                {
                        table_index++;
                        block_count++;
                        char str[30];
                        sprintf(str,"BLOCK %d", block_count);
                        table_list[table_index].name = strdup(str);
                        table_list[table_index].num_entries = 0;
                }
        '(' init_stmt ';' cond
                {
                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries], "label label");
                        char *temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"%d", label_count);
                        strcat(code->instructions[code->num_entries],temp);
                        code->num_entries++;

                        $6->label = (char *)malloc(200*sizeof(char));
                        strcpy($6->label,temp);

                        for(int i=0; i < $6->num_entries;i++)
                        {
                                code->instructions[code->num_entries+i] = $6->instructions[i];
                        }
                        code->num_entries += $6->num_entries;

                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries],$6->instruction_type);
                        strcat(code->instructions[code->num_entries], " label");
                        temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"%d", label_count+3);
                        strcat(code->instructions[code->num_entries],temp);
                        code->num_entries++;
                        
                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries], "jmp label");
                        temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"%d", label_count+2);
                        strcat(code->instructions[code->num_entries],temp);
                        code->num_entries++;

                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries], "label label");
                        temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"%d", label_count+1);
                        strcat(code->instructions[code->num_entries],temp);
                        code->num_entries++;
                        
                        label_count += 4;
                }
        ';' incr_stmt ')'
                {
                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries], "jmp label");
                        strcat(code->instructions[code->num_entries],$6->label);
                        code->num_entries++;

                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries], "label label");
                        int temp_label_count = atoi($6->label);
                        char *temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"%d", temp_label_count+2);
                        strcat(code->instructions[code->num_entries],temp);
                        code->num_entries++;
                }
        decl aug_stmt_list ROF
        {
                int temp_label_count = atoi($6->label);
                char *temp = (char *)malloc(200*sizeof(char));
                sprintf(temp,"%d", temp_label_count+1);
                code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                strcat(code->instructions[code->num_entries], "jmp label");
                strcat(code->instructions[code->num_entries],temp);
                code->num_entries++;

                code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                strcat(code->instructions[code->num_entries], "label label");
                temp = (char *)malloc(200*sizeof(char));
                sprintf(temp,"%d", temp_label_count+3);
                strcat(code->instructions[code->num_entries],temp);
                code->num_entries++;

                for(int i=0;i<code->num_entries;i++)
                {
                        if(!strcmp(code->instructions[i],"break"))
                        {
                                code->instructions[i] = (char *)malloc(200*sizeof(char));
                                strcat(code->instructions[i],"jmp label");
                                temp = (char *)malloc(200*sizeof(char));
                                sprintf(temp,"%d", temp_label_count+3);
                                strcat(code->instructions[i],temp);
                        }
                        if(!strcmp(code->instructions[i],"continue"))
                        {
                                code->instructions[i] = (char *)malloc(200*sizeof(char));
                                strcat(code->instructions[i],"jmp label");
                                temp = (char *)malloc(200*sizeof(char));
                                sprintf(temp,"%d", temp_label_count+1);
                                strcat(code->instructions[i],temp);
                        }
                }
        }
        ;
aug_stmt_list: aug_stmt aug_stmt_list |
        ;
aug_stmt: base_stmt | aug_if_stmt | for_stmt | CONTINUE ';'
        {
                code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                strcat(code->instructions[code->num_entries], "continue");
                code->num_entries++;
        }
| BREAK ';'
        {
                code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                strcat(code->instructions[code->num_entries], "break");
                code->num_entries++;
        }
        ;
aug_if_stmt: IF '(' cond ')'
                {                    
                        table_index++;
                        block_count++;
                        char str[30];
                        sprintf(str,"BLOCK %d", block_count);
                        table_list[table_index].name = strdup(str);
                        table_list[table_index].num_entries = 0;
                        for(int i=0; i < $3->num_entries;i++)
                        {
                                code->instructions[code->num_entries+i] = $3->instructions[i];
                        }
                        code->num_entries += $3->num_entries;
                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries],$3->instruction_type);
                        strcat(code->instructions[code->num_entries], " label");
                        char *temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"%d", label_count);
                        $3->label = temp;
                        strcat(code->instructions[code->num_entries],$3->label);
                        code->num_entries++;
                        label_count++;

                        label_count++;
                }
                decl aug_stmt_list
                {       
                        int jump = atoi($3->label);
                        jump++;
                        char *temp = (char *)malloc(200*sizeof(char));
                        sprintf(temp,"%d",jump);
                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries], "jmp label");
                        strcat(code->instructions[code->num_entries], temp);
                        code->num_entries++;

                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries], "label label");
                        strcat(code->instructions[code->num_entries],$3->label);
                        $3->label=temp;
                        code->num_entries++;
                }
                aug_else_part
                {
                        code->instructions[code->num_entries] = (char *)malloc(200*sizeof(char));
                        strcat(code->instructions[code->num_entries], "label label");
                        strcat(code->instructions[code->num_entries],$3->label);
                        code->num_entries++;
                }
        FI
        ;
aug_else_part: ELSE
                {                        
                        table_index++;
                        block_count++;
                        char str[30];
                        sprintf(str,"BLOCK %d", block_count);
                        table_list[table_index].name = strdup(str);
                        table_list[table_index].num_entries = 0;
                }
                decl aug_stmt_list |
        ;