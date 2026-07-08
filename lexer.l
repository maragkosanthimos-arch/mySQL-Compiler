%{
#include "parser.tab.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
int currLine = 1;

#define MAX 64548587
static char Buffer[MAX];
static int bufPosition=0;
static void store(void) {
    strncat(Buffer, yytext, sizeof(Buffer) - bufPosition - 1);
    bufPosition += yyleng;
}

char *getStoredProgram(void) {return Buffer;}

%}
%option case-insensitive
/* =======================
   CASE-INSENSITIVE KEYWORDS
   ======================= */
SELECT      select
FROM        from
WHERE       where
GROUP       group
ORDER       order
BY          by
LIMIT       limit
CREATE      create
TABLE       table
INT         int
FLOAT       float
VARCHAR     varchar
AND         and
OR          or
NOT         not
IN          in
AS          as
JOIN        join
ON          on
/* =======================
   IDENTIFIERS & LITERALS
   ======================= */
ID          [A-Za-z_][A-Za-z0-9_]*
INTNUM      -?[0-9]+
FLOATNUM    -?[0-9]+\.[0-9]+
STRING      \'([^\'\\]|\\.)*\'
WHITESPACE  [ \t\r]+
NEWLINE     \n
/* =======================
   COMMENTS
   ======================= */
COMMENT1    "--".*
COMMENT2    "/*"([^*]|\*+[^*/])*\*+"/"
%%

{SELECT}        {store(); return SELECT; }
{FROM}          {store();  return FROM; }
{WHERE}         {store();  return WHERE; }
{GROUP}         {store();  return GROUP; }
{ORDER}         {store();  return ORDER; }
{BY}            {store();  return BY; }
{LIMIT}         {store();  return LIMIT; }
{CREATE}        {store();  return CREATE; }
{TABLE}         {store();  return TABLE; }
{INT}           {store();  return INT_T; }
{FLOAT}         {store();  return FLOAT_T; }
{VARCHAR}       {store();  return VARCHAR_T; }
{AND}           {store();  return AND; }
{OR}            {store();  return OR; }
{NOT}           {store();  return NOT; }
{IN}            {store();  return IN; }
{AS}            {store();  return AS; }
{JOIN}          {store();  return JOIN; }
{ON}            {store();  return ON; }

{INTNUM}    {store();  yylval.intVal   = atoi(yytext); return INTNUM; }
{FLOATNUM}  {store();  yylval.floatVal = atof(yytext); return FLOATNUM; }
{STRING}    {store();  yylval.strVal   = strdup(yytext); return STRING; }
{ID}        {store();  yylval.strVal   = strdup(yytext); return ID; }

">="        {store();  return GEQ; }
"<="        {store();  return LEQ; }
"!="        {store();  return NEQ; }
">"         {store();  return GT; }
"<"         {store();  return LT; }
"="         {store();  return EQ; }

";"         {store();  return SEMICOLON; }
","         {store();  return COMMA; }
"("         {store();  return LPAR; }
")"         {store();  return RPAR; }
"*"         {store();  return STAR; }
"."         {store();  return DOT; }

{COMMENT1}  {store(); }
{COMMENT2}  {store(); }
{WHITESPACE} {store(); }
{NEWLINE}   {store(); currLine++; }

. {
    printf("Unknown token '%s' at line %d\n", yytext, currLine);
    store();
    return ERROR;
}
%%
int yywrap() {return 1;}
