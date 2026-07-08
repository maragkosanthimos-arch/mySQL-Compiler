/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_PARSER_NEW_1_TAB_H_INCLUDED
# define YY_YY_PARSER_NEW_1_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    SELECT = 258,                  /* SELECT  */
    FROM = 259,                    /* FROM  */
    WHERE = 260,                   /* WHERE  */
    GROUP = 261,                   /* GROUP  */
    ORDER = 262,                   /* ORDER  */
    BY = 263,                      /* BY  */
    LIMIT = 264,                   /* LIMIT  */
    CREATE = 265,                  /* CREATE  */
    TABLE = 266,                   /* TABLE  */
    INT_T = 267,                   /* INT_T  */
    FLOAT_T = 268,                 /* FLOAT_T  */
    VARCHAR_T = 269,               /* VARCHAR_T  */
    AND = 270,                     /* AND  */
    OR = 271,                      /* OR  */
    NOT = 272,                     /* NOT  */
    IN = 273,                      /* IN  */
    AS = 274,                      /* AS  */
    JOIN = 275,                    /* JOIN  */
    ON = 276,                      /* ON  */
    FLOATNUM = 277,                /* FLOATNUM  */
    INTNUM = 278,                  /* INTNUM  */
    STRING = 279,                  /* STRING  */
    ID = 280,                      /* ID  */
    GEQ = 281,                     /* GEQ  */
    LEQ = 282,                     /* LEQ  */
    NEQ = 283,                     /* NEQ  */
    GT = 284,                      /* GT  */
    LT = 285,                      /* LT  */
    EQ = 286,                      /* EQ  */
    SEMICOLON = 287,               /* SEMICOLON  */
    COMMA = 288,                   /* COMMA  */
    LPAR = 289,                    /* LPAR  */
    RPAR = 290,                    /* RPAR  */
    STAR = 291,                    /* STAR  */
    DOT = 292,                     /* DOT  */
    ERROR = 293                    /* ERROR  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 224 "parser_new_1.y"

    int    intVal;
    double floatVal;
    char  *strVal;
    int    typeVal;

#line 109 "parser_new_1.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);


#endif /* !YY_YY_PARSER_NEW_1_TAB_H_INCLUDED  */
