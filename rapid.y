%{
#include <stdio.h>
#include <math.h>
#include "rapid.tab.h"
#include <string.h>
#include <stdbool.h>

#define YYERROR_VERBOSE 1

#define FOREACH_TYPE(TYPE) \
        TYPE(variable_)   \
        TYPE(predicate)  \
        TYPE(const_real)   \
        TYPE(const_int)   \

#define GENERATE_ENUM(ENUM) ENUM,
#define GENERATE_STRING(STRING) #STRING,

// Enumeration for all Types with according Strings
enum TYPE_ENUM {
  FOREACH_TYPE(GENERATE_ENUM)
};

static const char *TYPE_STRING[] = {
  FOREACH_TYPE(GENERATE_STRING)
};

// Symbol Table consisting of Structs of Symbols
struct symbol {
    int clause;
    char id[30];
    enum TYPE_ENUM type;
    union {
      int val_int;
      double val_real;
   } value;
   int occ[25];
   int occ_c;
};

int clause_count;
int clause_start;

int pred_count;

int c;
struct symbol symtable[500];

void yyerror(const char *);
int yylex();

bool strCmp(char*, char*);
int indexOf(const char*);
void printTable();

%}

%token left_arrow is
%token atom variable 
%token number rnum string
%token open_round_brackets close_round_brackets
%token open_square_brackets close_square_brackets
%token pipesym
%token dot comma
%token smaller greater equal whatthehell
%token plus minus times divby
%token comment ml_comment
%token end undefined

%union {
  int integer;
  double real;
  char* str;
}

%type<str> atom
%type<str> variable
%type<real> rnum
%type<integer> number

%type <str> Clause

%start S

%left smaller greater equal

%left plus minus
%left times divby


%%

S: Clause end { 
    printf("\n\t => %s \n\n", $1);
    //printTable();
  }
 | S Clause end {
    clause_start = c;
    clause_count++;
    printf("\n\t => %s \n\n", $2); 
    //printTable();
  }
  | S end;
  | end;

Clause: Rule dot { $$ = "Rule"; }
  | Fact dot { $$ = "Fact"; }
  | Comment { $$ = "Comment"; };

Rule: Predicate left_arrow PredicateList { 
  printf(" Rule "); 
  pred_count = 0;
  };

Fact: Predicate { printf("Fact"); };

PredicateList: Predicate { printf(" PredicateList "); ; }
  | Predicate comma PredicateList { 
      printf(" PredicateList ");
      pred_count++;
  };

Predicate: atom open_round_brackets TermList close_round_brackets {
    printf("Predicate %s", $1);
    symtable[c].clause = clause_count;
    strncpy(symtable[c].id, $1, sizeof(symtable[c].id));

    symtable[c].type = predicate;
    c++;
  }
  | Condition {printf(" Predicate "); }
  | Assignment {printf(" Predicate "); }
  | Definition {printf(" Predicate "); };

TermList: Term { printf(" TermList "); }
  | Term comma TermList { printf(" TermList "); };

Term: Function { printf(" Term "); }
  | List { printf(" Term "); }
  | Operand { printf(" Term "); };

Function: atom open_round_brackets TermList close_round_brackets{
    printf(" Function "); };

List: open_square_brackets TermList close_square_brackets {
    printf(" List "); 
  }
  | open_square_brackets List close_square_brackets {
    printf(" List "); 
  }
  | open_square_brackets TermList comma List close_square_brackets {
    printf(" List "); 
  }
  | open_square_brackets TermList pipesym Term close_square_brackets {
    printf(" List "); 
  };

Operand: variable { 
    printf(" Operand-variable %s", $1); 
    symtable[c].clause = clause_count;

    strncpy(symtable[c].id, $1, sizeof(symtable[c].id));
    symtable[c].type = variable_;
    symtable[c].occ_c = 0;
    c++;
    
    // check if in table
    //int i = indexOf(symtable[c].id);
    //printf("\nI: %d\n", i);

/*
    if(i == -1) {

    } else {
      sym = symtable[i];
      sym.occ[sym.occ_c] = pred_count;
      sym.occ_c++;
    }
    */

  }
  | Operation { printf(" Operand "); }
  | Constant { printf(" Operand "); };

Constant: number { 
    printf(" Constant %d ", $1);
    symtable[c].clause = clause_count;
    symtable[c].value.val_int = $1;
    symtable[c].type = const_int;
    c++;
  }
  | rnum { 
    printf(" Constant %lf ", $1);
    symtable[c].clause = clause_count;
    symtable[c].value.val_real = $1;
    symtable[c].type = const_real;
    c++;
  };

Operation: open_round_brackets Operation close_round_brackets { printf(" Operation "); }
  | Operand plus Operand { printf(" Operation "); }
  | Operand minus Operand { printf(" Operation "); }
  | Operand times Operand { printf(" Operation "); }
  | Operand divby Operand { printf(" Operation "); };

Condition: Operand greater Operand { printf(" Condition "); }
  | Operand smaller Operand { printf(" Condition "); }
  | Operand greater equal Operand { printf(" Condition "); }
  | Operand equal smaller Operand { printf(" Condition "); }
  | Operand equal equal Operand { printf(" Condition "); }
  | Operand whatthehell equal equal Operand { printf(" Condition "); };

Assignment: Operand equal Operand { printf(" Assignment "); }
  | Operand whatthehell equal Operand { printf(" Assignment "); };

Definition: Term is Term { printf(" Definition "); };

Comment: comment { printf(" Comment "); }
  | ml_comment { printf(" Comment "); };

%%

int main(void) {
  clause_count = 0;

  yyparse();
  printTable();

  return 1;
}

void yyerror(const char* e) {
  printf("Error: %s\n", e);
}

bool strCmp(char* l, char* r) {  
  while(*l != '\0' && *r != '\0') {
    if(*l != *r) {
      return false;
    }
    l++;
    r++;
  }

  if(*l == '\0' && *r == '\0') {
    return true;
  } 
  
  return false;
}


int indexOf(const char* id) {
  
  int i=clause_start;
  while(i != c && i < 500) {
    printf("I: %d", i);
    /*
    if(strCmp(symtable[i].id, id)) {
      return i;
    }
    */
    i++;
  }

  return -1;
}


void printTable() {
  printf("Index\tClause\tIdentifier\tName\tType\tValue\n");
  
  struct symbol sym = {};
  int current_clause = 0;

  for(int i=0; i<c; i++) {
    printf("%d\t", i);

    if(symtable[i].clause != current_clause || i == 0) {
      printf("%d\t", symtable[i].clause);
      current_clause = symtable[i].clause;
    } else {
      printf("\t");
    }

    sym = symtable[i];

    printf("%s\t%s\t", sym.id, TYPE_STRING[sym.type]);

    if(sym.type == const_int) {
      printf("%d\n", sym.value.val_int);
    } else if(sym.type == const_real) {
      printf("%lf\n", sym.value.val_real);
    } else {
      printf("\n");
    }
  }
}