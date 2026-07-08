%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*παρεχονται απο lexer*/
extern int   currLine;
extern char *getStoredProgram(void);
extern int   yylex(void);

/*forward δήλωση - πετάει μήνυμα σφάλματος*/
void yyerror(const char *msg);

/*μεταβλητη ορθότητας προγράμματος - σωστό ή error*/
static int parseOK = 1;

/* ======================================================
                    ΠΙΝΚΑΣ ΣΥΜΒΟΛΩΝ
   ====================================================== */

#define MAX 500
#define INT     0
#define FLOAT   1
#define VARCHAR 2

typedef struct {
    char *name;
    int   type;
} Column;

typedef struct {
    char   *tableName;
    Column  columns[MAX];
    int     colCount;
} Table;

static Table tables[MAX];
static int   tableCount = 0;

/* Μετρητής στηλών για τον πίνακα που ορίζεται τώρα */
static int colNum = 0;

/* ======================================================
   ACTIVE TABLES ΓΙΑ ΤΟ ΤΡΕΧΟΝ SELECT
   Κρατάμε τους πίνακες που συμμετέχουν στο τρέχον
   ερώτημα (FROM + JOINs), και το alias τους αν υπάρχει.
   ====================================================== */

typedef struct {
    char *tableName;   /* πραγματικό όνομα πίνακα */
    char *alias;       /* NULL αν δεν υπάρχει alias */
} ActiveTable;

static ActiveTable activeList[MAX];
static int         activeCount = 0;

/* Καθαρίζει τη λίστα ενεργών πινάκων (καλείται στην αρχή κάθε SELECT) */
static void clearActive(void) {
    int i;
    for (i = 0; i < activeCount; i++) {
        free(activeList[i].tableName);
        if (activeList[i].alias) free(activeList[i].alias);
    }
    activeCount = 0;
}

/* Προσθέτει πίνακα στη λίστα ενεργών.
   Επιστρέφει 0 αν το alias χρησιμοποιείται ήδη. */
static int addActive(const char *tableName, const char *alias) {
    int i;
    if (alias) {
        for (i = 0; i < activeCount; i++) {
            if (activeList[i].alias &&
                strcmp(activeList[i].alias, alias) == 0) return 0;
        }
    }
    activeList[activeCount].tableName = strdup(tableName);
    activeList[activeCount].alias     = alias ? strdup(alias) : NULL;
    activeCount++;
    return 1;
}

/*
 * Επιλύει ένα "qualifier" (που μπορεί να είναι πραγματικό όνομα πίνακα
 * ή alias) σε πραγματικό όνομα πίνακα.
 * Επιστρέφει NULL αν δεν βρεθεί.
 */
static const char *resolveQualifier(const char *qualifier) {
    int i;
    for (i = 0; i < activeCount; i++) {
        /* Ελέγχουμε alias πρώτα */
        if (activeList[i].alias &&
            strcmp(activeList[i].alias, qualifier) == 0)
            return activeList[i].tableName;
        /* Μετά το πραγματικό όνομα (αν δεν έχει alias) */
        if (!activeList[i].alias &&
            strcmp(activeList[i].tableName, qualifier) == 0)
            return activeList[i].tableName;
    }
    return NULL;
}

/*
 * Ελέγχει αν ένας qualifier (alias ή table name) υπάρχει στη λίστα
 * ενεργών.
 */
static int activeQualifierExists(const char *qualifier) {
    return resolveQualifier(qualifier) != NULL;
}

/* ------------------------------------------------------ */

static int tableExists(const char *name) {
    int i;
    for (i = 0; i < tableCount; i++)
        if (strcmp(tables[i].tableName, name) == 0)
            return 1;
    return 0;
}

static int searchName(const char *tableName, const char *columnName) {
    int i, j;
    for (i = 0; i < tableCount; i++) {
        if (strcmp(tables[i].tableName, tableName) == 0) {
            for (j = 0; j < tables[i].colCount; j++) {
                if (strcmp(tables[i].columns[j].name, columnName) == 0)
                    return 1;
            }
        }
    }
    return 0;
}

static int getColumnType(const char *tableName, const char *columnName) {
    int i, j;
    for (i = 0; i < tableCount; i++) {
        if (strcmp(tables[i].tableName, tableName) == 0) {
            for (j = 0; j < tables[i].colCount; j++) {
                if (strcmp(tables[i].columns[j].name, columnName) == 0)
                    return tables[i].columns[j].type;
            }
        }
    }
    return -1;
}

static int addColumn(const char *name, int type) {
    int i;
    for (i = 0; i < colNum; i++) {
        if (strcmp(tables[tableCount].columns[i].name, name) == 0)
            return 0;
    }
    tables[tableCount].columns[colNum].name = strdup(name);
    tables[tableCount].columns[colNum].type = type;
    colNum++;
    return 1;
}

static void resetColumns(void) { colNum = 0; }

static int compatible(int colType, int litType) {
    if (colType == INT)     return litType == INT;
    if (colType == FLOAT)   return litType == INT || litType == FLOAT;
    if (colType == VARCHAR) return litType == VARCHAR;
    return 0;
}

/*
 * Ψάχνει μια στήλη σε ΟΛΟΥΣ τους ενεργούς πίνακες (χωρίς qualifier).
 * Χρησιμοποιείται για SELECT *, col_name_list χωρίς alias.
 * Επιστρέφει τον τύπο ή -1 αν δεν βρεθεί.
 */
static int searchInAllActive(const char *columnName) {
    int i;
    for (i = 0; i < activeCount; i++) {
        if (searchName(activeList[i].tableName, columnName))
            return getColumnType(activeList[i].tableName, columnName);
    }
    return -1;
}

/*
 * Ελέγχει αν το ερώτημα χρησιμοποιεί aliases.
 * Αν ΝΑΙ, οι στήλες πρέπει ΠΑΝΤΑ να γράφονται ως alias.col ή table.col.
 */
static int queryHasAliases(void) {
    int i;
    for (i = 0; i < activeCount; i++)
        if (activeList[i].alias) return 1;
    return 0;
}


typedef struct {
    char *qualifier;
    char *colName;
    int   line;
} DeferredCheck;

static DeferredCheck deferredCols[MAX];
static int           deferredCount = 0;
static int           current_in_type = -1;

static void addDeferredCheck(const char *qual, const char *col) {
    deferredCols[deferredCount].qualifier = qual ? strdup(qual) : NULL;
    deferredCols[deferredCount].colName   = strdup(col);
    deferredCols[deferredCount].line      = currLine;
    deferredCount++;
}

static void clearDeferred(void) {
    int i;
    for (i = 0; i < deferredCount; i++) {
        if (deferredCols[i].qualifier) free(deferredCols[i].qualifier);
        free(deferredCols[i].colName);
    }
    deferredCount = 0;
}

%}

/* ==========================
   UNION - semantic values
   ========================== */
%union {
    int    intVal;
    double floatVal;
    char  *strVal;
    int    typeVal;
}

/* ==========================
   TOKEN DECLARATIONS
   ========================== */
%token SELECT FROM WHERE GROUP ORDER BY LIMIT
%token CREATE TABLE
%token INT_T FLOAT_T VARCHAR_T
%token AND OR NOT IN
%token AS JOIN ON
%token <floatVal> FLOATNUM
%token <intVal>   INTNUM
%token <strVal>   STRING ID
%token GEQ LEQ NEQ GT LT EQ
%token SEMICOLON COMMA LPAR RPAR STAR DOT
%token ERROR

%type <typeVal> data_type
%type <typeVal> literal
%type <typeVal> expr
%type <strVal>  column_ref

/* ==========================
   OPERATOR PRECEDENCE
   ========================== */
%left  OR
%left  AND
%right NOT

%%

/* ======================================================
   PROGRAM
   ====================================================== */

program
    : statement_list
    ;

statement_list
    : statement SEMICOLON
    | statement_list statement SEMICOLON
    ;

statement
    : select_stmt
    | create_stmt
    ;

/* ======================================================
   SELECT
   Η σειρά: SELECT from_clause join_list select_list ...
   Το from_clause (+ join_list) ορίζει τους ενεργούς
   πίνακες πριν ελεγχθούν οι στήλες.
   ====================================================== */

select_stmt
    : SELECT { clearDeferred(); } select_list from_clause join_list opt_where opt_groupby opt_orderby opt_limit
        {
            /* Έλεγχος των στηλών του SELECT list αφού έχει γεμίσει πλέον η activeList */
            int i;
            int has_aliases = queryHasAliases();
            for (i = 0; i < deferredCount; i++) {
                if (deferredCols[i].qualifier == NULL) {
                    if (has_aliases) {
                        char msg[MAX*2];
                        snprintf(msg, sizeof(msg),
                            "Column '%s' must be qualified with a table alias when aliases are used",
                            deferredCols[i].colName);
                        int saveLine = currLine;
                        currLine = deferredCols[i].line;
                        yyerror(msg);
                        currLine = saveLine;
                        clearDeferred();
                        clearActive();
                        YYERROR;
                    }
                    int t = searchInAllActive(deferredCols[i].colName);
                    if (t == -1) {
                        char msg[MAX*2];
                        snprintf(msg, sizeof(msg),
                            "Column '%s' does not exist in any active table",
                            deferredCols[i].colName);
                        int saveLine = currLine;
                        currLine = deferredCols[i].line;
                        yyerror(msg);
                        currLine = saveLine;
                        clearDeferred();
                        clearActive();
                        YYERROR;
                    }
                } else {
                    const char *tbl = resolveQualifier(deferredCols[i].qualifier);
                    if (!tbl) {
                        char msg[MAX*2];
                        snprintf(msg, sizeof(msg),
                            "Unknown table or alias '%s'",
                            deferredCols[i].qualifier);
                        int saveLine = currLine;
                        currLine = deferredCols[i].line;
                        yyerror(msg);
                        currLine = saveLine;
                        clearDeferred();
                        clearActive();
                        YYERROR;
                    }
                    if (!searchName(tbl, deferredCols[i].colName)) {
                        char msg[MAX*2];
                        snprintf(msg, sizeof(msg),
                            "Column '%s' does not exist in table '%s'",
                            deferredCols[i].colName, tbl);
                        int saveLine = currLine;
                        currLine = deferredCols[i].line;
                        yyerror(msg);
                        currLine = saveLine;
                        clearDeferred();
                        clearActive();
                        YYERROR;
                    }
                }
            }
            clearDeferred();
            clearActive();
        }
    ;


/* ======================================================
   ====================================================== */

select_list
    : STAR
    | deferred_col_name_list
    ;

deferred_col_name_list
    : deferred_col_item
    | deferred_col_name_list COMMA deferred_col_item
    ;

deferred_col_item
    : ID
        {
            addDeferredCheck(NULL, $1);
            free($1);
        }
    | ID DOT ID
        {
            addDeferredCheck($1, $3);
            free($1); free($3);
        }
    ;

/* ======================================================
   FROM CLAUSE — υποστηρίζει προαιρετικό AS alias
   ====================================================== */

from_clause
    : FROM ID
        {
            /* χωρίς alias */
            if (!tableExists($2)) {
                char msg[MAX * 2];
                snprintf(msg, sizeof(msg),
                    "Table '%s' has not been defined with CREATE TABLE", $2);
                yyerror(msg); free($2); YYERROR;
            }
            clearActive();
            addActive($2, NULL);
            free($2);
        }
    | FROM ID AS ID
        {
            /* με alias */
            if (!tableExists($2)) {
                char msg[MAX * 2];
                snprintf(msg, sizeof(msg),
                    "Table '%s' has not been defined with CREATE TABLE", $2);
                yyerror(msg); free($2); free($4); YYERROR;
            }
            clearActive();
            if (!addActive($2, $4)) {
                char msg[MAX * 2];
                snprintf(msg, sizeof(msg),
                    "Alias '%s' is already in use", $4);
                yyerror(msg); free($2); free($4); YYERROR;
            }
            free($2); free($4);
        }
    ;

/* ======================================================
   JOIN LIST — 0 ή περισσότερα JOIN
   ====================================================== */

join_list
    : /* empty */
    | join_list join_clause
    ;

join_clause
    : JOIN ID 
        {
            /* χωρίς alias — ελέγχουμε αφού το προσθέσουμε */
            if (!tableExists($2)) {
                char msg[MAX * 2];
                snprintf(msg, sizeof(msg),
                    "Table '%s' has not been defined with CREATE TABLE", $2);
                yyerror(msg); free($2); YYERROR;
            }
            addActive($2, NULL);
        }
    ON join_condition
    {
        free($2);
    }
    | JOIN ID AS ID 
        {
            /* με alias */
            if (!tableExists($2)) {
                char msg[MAX * 2];
                snprintf(msg, sizeof(msg),
                    "Table '%s' has not been defined with CREATE TABLE", $2);
                yyerror(msg); free($2); free($4); YYERROR;
            }
            if (!addActive($2, $4)) {
                char msg[MAX * 2];
                snprintf(msg, sizeof(msg),
                    "Alias '%s' is already in use", $4);
                yyerror(msg); free($2); free($4); YYERROR;
            }
        }
    ON join_condition{
        free($2); free($4);
    }
    ;

/*
 * Η συνθήκη του ON: qualifier1.col1 = qualifier2.col2
 * Ελέγχουμε ότι αμφότεροι οι qualifiers και οι στήλες υπάρχουν.
 * ΣΗΜΕΙΩΣΗ: Ο δεξί πίνακας (qualifier2) μπορεί να είναι ο νέος πίνακας
 * που μόλις προστέθηκε, οπότε τον αναζητούμε απευθείας στο tableExists.
 */
join_condition
    : ID DOT ID EQ ID DOT ID
        {
            /* $1.$3 = $5.$7 */
            const char *tbl1 = resolveQualifier($1);
            const char *tbl2 = resolveQualifier($5);

            /* Ο δεξί qualifier μπορεί να είναι ο νέος πίνακας που δεν έχει
               μπει ακόμα στο activeList (join χωρίς AS). Αν δεν βρεθεί με
               resolve, δοκιμάζουμε απευθείας ως όνομα πίνακα. */
            if (!tbl1) {
                if (tableExists($1)) tbl1 = $1;
                else {
                    char msg[MAX*2];
                    snprintf(msg, sizeof(msg),
                        "Unknown table or alias '%s' in JOIN condition", $1);
                    yyerror(msg);
                    free($1);free($3);free($5);free($7); YYERROR;
                }
            }
            if (!tbl2) {
                if (tableExists($5)) tbl2 = $5;
                else {
                    char msg[MAX*2];
                    snprintf(msg, sizeof(msg),
                        "Unknown table or alias '%s' in JOIN condition", $5);
                    yyerror(msg);
                    free($1);free($3);free($5);free($7); YYERROR;
                }
            }
            if (!searchName(tbl1, $3)) {
                char msg[MAX*2];
                snprintf(msg, sizeof(msg),
                    "Column '%s' does not exist in table '%s'", $3, tbl1);
                yyerror(msg);
                free($1);free($3);free($5);free($7); YYERROR;
            }
            if (!searchName(tbl2, $7)) {
                char msg[MAX*2];
                snprintf(msg, sizeof(msg),
                    "Column '%s' does not exist in table '%s'", $7, tbl2);
                yyerror(msg);
                free($1);free($3);free($5);free($7); YYERROR;
            }
            free($1);free($3);free($5);free($7);
        }
    ;

/* ======================================================
   OPTIONAL CLAUSES
   ====================================================== */

opt_where
    : /* empty */
    | WHERE condition
    ;

opt_groupby
    : /* empty */
    | GROUP BY col_name_list
    ;

opt_orderby
    : /* empty */
    | ORDER BY col_name_list
    ;

opt_limit
    : /* empty */
    | LIMIT INTNUM
        {
            if ($2 <= 0) {
                yyerror("LIMIT value must be a strictly positive integer");
                YYERROR;
            }
        }
    ;


/* ======================================================
   CONDITIONS
   ====================================================== */

condition
    : condition AND condition
    | condition OR  condition
    | NOT condition
    | LPAR condition RPAR
    | expr cmp_op expr
        {
            if ($1 != -1 && $3 != -1 && !compatible($1, $3)) {
                yyerror("Types are not compatible in WHERE clause!");
                YYERROR;
            }
        }
    | expr IN     LPAR value_list RPAR
    | expr NOT IN LPAR value_list RPAR
    ;

cmp_op
    : EQ | NEQ | LT | GT | LEQ | GEQ
    ;

/* ======================================================
   EXPRESSIONS
   ====================================================== */

expr
    : column_ref  { $$ = $1; }
    | literal     { $$ = $1; }
    | LPAR expr RPAR { $$ = $2; }
    ;

/*
 * column_ref επιστρέφει τον τύπο της στήλης (int).
 * Υποστηρίζει:
 *   ID           — απλή στήλη, αναζήτηση σε όλους ενεργούς πίνακες
 *   ID DOT ID    — qualifier.column (qualifier = alias ή table name)
 */
column_ref
    : ID
        {
            /* Αν υπάρχουν aliases, ΔΕΝ επιτρέπεται χωρίς qualifier */
            if (queryHasAliases()) {
                char msg[MAX*2];
                snprintf(msg, sizeof(msg),
                    "Column '%s' must be qualified with a table alias when aliases are used",
                    $1);
                yyerror(msg); free($1); YYERROR;
            }
            int t = searchInAllActive($1);
            if (t == -1) {
                char msg[MAX*2];
                snprintf(msg, sizeof(msg),
                    "Column '%s' does not exist in any active table", $1);
                yyerror(msg); free($1); YYERROR;
            }
            free($1);
            $$ = t;
        }
    | ID DOT ID
        {
            /* $1 = qualifier (alias ή table name), $3 = column name */
            const char *tbl = resolveQualifier($1);
            if (!tbl) {
                char msg[MAX*2];
                snprintf(msg, sizeof(msg),
                    "Unknown table or alias '%s'", $1);
                yyerror(msg); free($1); free($3); YYERROR;
            }
            if (!searchName(tbl, $3)) {
                char msg[MAX*2];
                snprintf(msg, sizeof(msg),
                    "Column '%s' does not exist in table '%s'", $3, tbl);
                yyerror(msg); free($1); free($3); YYERROR;
            }
            int t = getColumnType(tbl, $3);
            free($1); free($3);
            $$ = t;
        }
    ;

literal
    : INTNUM   { $$ = INT; }
    | FLOATNUM { $$ = FLOAT; }
    | STRING   { free($1); $$ = VARCHAR; }
    ;

value_list
    : literal
    | value_list COMMA literal
    ;

/* ======================================================
   COLUMN-NAME LIST (SELECT list, GROUP BY, ORDER BY)
   Υποστηρίζει:
     ID           — αναζήτηση σε όλους ενεργούς (χωρίς aliases)
     ID DOT ID    — qualified (με ή χωρίς aliases)
   ====================================================== */

col_name_list
    : col_item
    | col_name_list COMMA col_item
    ;

col_item
    : ID
        {
            if (queryHasAliases()) {
                char msg[MAX*2];
                snprintf(msg, sizeof(msg),
                    "Column '%s' must be qualified with a table alias when aliases are used",
                    $1);
                yyerror(msg); free($1); YYERROR;
            }
            if (searchInAllActive($1) == -1) {
                char msg[MAX*2];
                snprintf(msg, sizeof(msg),
                    "Column '%s' does not exist in any active table", $1);
                yyerror(msg); free($1); YYERROR;
            }
            free($1);
        }
    | ID DOT ID
        {
            const char *tbl = resolveQualifier($1);
            if (!tbl) {
                char msg[MAX*2];
                snprintf(msg, sizeof(msg),
                    "Unknown table or alias '%s'", $1);
                yyerror(msg); free($1); free($3); YYERROR;
            }
            if (!searchName(tbl, $3)) {
                char msg[MAX*2];
                snprintf(msg, sizeof(msg),
                    "Column '%s' does not exist in table '%s'", $3, tbl);
                yyerror(msg); free($1); free($3); YYERROR;
            }
            free($1); free($3);
        }
    ;

/* ======================================================
   CREATE TABLE
   ====================================================== */

create_stmt
    : CREATE TABLE ID
        {
            if (tableExists($3)) {
                char msg[MAX * 2];
                snprintf(msg, sizeof(msg),
                    "Table '%s' already exists (duplicate CREATE TABLE)", $3);
                yyerror(msg); free($3); YYERROR;
            }
            resetColumns();
            tables[tableCount].tableName = strdup($3);
            free($3);
        }
      LPAR col_def_list RPAR
        {
            tables[tableCount].colCount = colNum;
            tableCount++;
        }
    ;

col_def_list
    : col_def
    | col_def_list COMMA col_def
    ;

col_def
    : ID data_type
        {
            if (!addColumn($1, $2)) {
                char msg[MAX * 2];
                snprintf(msg, sizeof(msg),
                    "Duplicate column name '%s' in CREATE TABLE", $1);
                yyerror(msg); free($1); YYERROR;
            }
            free($1);
        }
    ;

data_type
    : INT_T     { $$ = INT; }
    | FLOAT_T   { $$ = FLOAT; }
    | VARCHAR_T LPAR INTNUM RPAR
        {
            if ($3 <= 0) {
                yyerror("VARCHAR size must be a strictly positive integer");
                YYERROR;
            }
            $$ = VARCHAR;
        }
    ;

%%

/* ======================================================
   ERROR HANDLER
   ====================================================== */
void yyerror(const char *msg) {
    parseOK = 0;
    printf("\n--- Program (printed up to the error line) ---\n");
    printf("%s", getStoredProgram());
    printf("\n----------------------------------------------\n");
    fprintf(stderr, "Syntax error at line %d: %s\n", currLine, msg);
}

/* ======================================================
   MAIN
   ====================================================== */
int main(int argc, char **argv) {
    extern FILE *yyin;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s <file_name>\n", argv[0]);
        return 1;
    }

    FILE *fp = fopen(argv[1], "r");
    if (!fp) {
        fprintf(stderr, "Error: Cannot open file '%s'\n", argv[1]);
        return 1;
    }

    yyin = fp;
    yyparse();
    fclose(fp);

    if (parseOK) {
        printf("\n--- Program ---\n");
        printf("%s", getStoredProgram());
        printf("---------------\n");
        printf("The program is syntactically CORRECT.\n");
        return 0;
    }
    return 1;
}
