%{
#include <stdio.h>
#include <math.h>
#include "rapid.tab.h"
#include <string.h>
#include <stdbool.h>

#define YYERROR_VERBOSE 1

typedef struct var {
  char *id;
  struct var* next;
} var;

typedef struct predicate {
  char *id;
  var* first_var;
  struct predicate* next;
} predicate;

typedef struct clause {
  char *type; // rule or fact
  predicate* head;
  predicate* first_subgoal;
  struct clause* next;
} clause;

clause* create_clause();
clause* add_clause(clause*);

predicate* create_predicate();
predicate* add_predicate(predicate*, predicate*);

void printClauses();
void printPredicate(predicate*);
void printVariables(var*);

var* create_variable(char*);
void add_variable(var*);

// global pointer
clause* head;
clause* current_clause;
predicate* current_predicate;

var* first_variable;
var* current_variable;

int clause_count = 0;

void yyerror(const char *);
int yylex();

%}

%token left_arrow is
%token atom variable 
%token num real string
%token open_round_brackets close_round_brackets
%token open_square_brackets close_square_brackets
%token pipesym
%token dot comma
%token smaller greater equal colon whatthehell
%token plus minus times divby
%token comment ml_comment
%token end undefined

%union {
  char* str;
  struct predicate* pred;
  struct clause* clause;
}

%type<str> atom variable
%type<str> Term TermList Operand Function List RestList
%type<str> Operation Constant Condition Assignment
%type<str> num real

%type<clause> Rule Fact Clause

%type<pred> Predicate PredMark PredicateList

%start S

%left smaller greater equal

%left plus minus
%left times divby


%%

S: M Clause { 
    printf("\n\t => %s \n\n", $2->type);
  }
  | S M Clause {
    printf("\n\t => %s \n\n", $3->type); 
  }
  | S Comment;
  | Comment;
  | S end;
  | end;

M: { printf("%d\n", clause_count);
  clause_count++;
  clause* new_clause = create_clause(); 
  add_clause(new_clause); 
  
  };

Clause: Rule { 
  current_clause->type = "rule";
  $$ = current_clause;
 }
  | Fact { 
    current_clause->type = "fact";
    $$ = current_clause; 
  };

Rule: Predicate left_arrow PredicateList dot {
    current_clause->head = $1;
    current_clause->first_subgoal = $3;
  };

Fact: Predicate dot {
    current_clause->head = $1;
    current_clause->first_subgoal = NULL;
  };

PredicateList: Predicate { $$ = $1; }
  | Predicate comma PredicateList { 
      predicate* head = $1;
      predicate* next = $3;

      head->next = next;
      $$ = head;      
  };

Predicate: atom open_round_brackets PredMark TermList close_round_brackets {
    printf(" %s(%s) ", $1, $4);
    predicate* new_pred = $3;
    new_pred->id = strdup($1);

    current_predicate->first_var = first_variable;

    $$ = new_pred;
  }
  | PredMark Condition {
    printf(" %s ", $2);
    predicate* new_pred = $1;
    new_pred->id = strdup($2);
    current_predicate->first_var = first_variable;
    $$ = new_pred;
   }
  | PredMark Assignment {
    printf(" %s ", $2);
    predicate* new_pred = $1;
    new_pred->id = strdup($2);
    current_predicate->first_var = first_variable;
    $$ = new_pred;
  };

PredMark: { predicate* new_pred = create_predicate(); 
    current_predicate = new_pred;
    first_variable = NULL;
    current_variable = NULL;
    $$ = new_pred; 
  };

TermList: Term { $$ = $1; }
  | Term comma TermList { asprintf(&$$, "%s, %s", $1, $3); 
  };
  
Term: Operand { $$ = $1; }
  | List { $$ = $1; }
  | Function { $$ = $1; };

Function: atom open_round_brackets TermList close_round_brackets {
    asprintf(&$$, "%s(%s)", $1, $3);
  };

List: open_square_brackets close_square_brackets { asprintf(&$$, "[]"); }
  | open_square_brackets Operand close_square_brackets { asprintf(&$$, "[%s]", $2); }
  | open_square_brackets List close_square_brackets { asprintf(&$$, "[%s]", $2); }
  | open_square_brackets List comma List close_square_brackets { asprintf(&$$, "[%s, %s]", $2, $4); }
  | open_square_brackets Operand pipesym RestList close_square_brackets { asprintf(&$$, "[%s|%s]", $2, $4); };

RestList: List {$$ = $1}
  | Operand {$$ = $1};

Operand: variable {
    var* v = create_variable($1);
    add_variable(v);
    $$ = v->id;
  }
  | Operation { $$ = $1; }
  | Constant { $$ = $1; };

Constant: num { $$ = $1; }
  | real { $$ = $1; };

Operation: open_round_brackets Operation close_round_brackets { asprintf(&$$, "(%s)", $2); }
  | Operand plus Operand { asprintf(&$$, "+(%s, %s)", $1, $3); }
  | Operand minus Operand { asprintf(&$$, "-(%s, %s)", $1, $3); }
  | Operand times Operand { asprintf(&$$, "*(%s, %s)", $1, $3); }
  | Operand divby Operand { asprintf(&$$, "/(%s, %s)", $1, $3); };

Condition: Operand greater Operand { asprintf(&$$, ">(%s, %s)", $1, $3); }
  | Operand smaller Operand { asprintf(&$$, "<(%s, %s)", $1, $3); }
  | Operand greater equal Operand { asprintf(&$$, ">=(%s, %s)", $1, $4); }
  | Operand equal smaller Operand { asprintf(&$$, "=<(%s, %s)", $1, $4); }
  | Operand equal equal Operand { asprintf(&$$, "==(%s, %s)", $1, $4); }
  | Operand equal colon equal Operand { asprintf(&$$, "=:=(%s, %s)", $1, $5); }
  | Operand equal whatthehell equal Operand { asprintf(&$$, "=\\=(%s, %s)", $1, $5); }
  | Operand whatthehell equal equal Operand { asprintf(&$$, "\\==(%s, %s)", $1, $5); }
  | Term is Operand { { asprintf(&$$, "is(%s, %s)", $1, $3); }; };

Assignment: Operand equal Operand { asprintf(&$$, "=(%s, %s)", $1, $3); }
  | Operand whatthehell equal Operand { asprintf(&$$, "\\=(%s, %s)", $1, $4); };

Comment: comment { }
  | ml_comment { };

%%

clause* create_clause() {
  clause* c = malloc(sizeof(struct clause));
  c->next = NULL;

  return c;
};

clause* add_clause(clause* c) {
  if(current_clause == NULL) {
    // List empty
    head = c;
  } else {
    current_clause->next = c;
  }

  current_clause = c;
  return c;
};

predicate* create_predicate() {
  predicate* p = malloc(sizeof(struct predicate));
  p->next = NULL;
  p->first_var = NULL;
  return p;
};

var* create_variable(char* id) {
  var* v = malloc(sizeof(struct var));
  v->id = strdup(id);
  v->next = NULL;
  
  return v;
};

void add_variable(var *v) {
  if(current_variable == NULL) {
    // list empty
    first_variable = v;
  } else {
    current_variable->next = v;
  }

  current_variable = v;

  printf("%s", v->id);
}



void printClauses() {
  int i = 1;
  clause* c = head;
  while(c != NULL) {
    printf("%d \t type: %s \n", i, c->type);

    printf("\t head: ");
    printPredicate(c->head);

    predicate* p = c->first_subgoal;
    int j = 1;
    while(p != NULL) {
      printf("\t subgoal %d: ", j);
      printPredicate(p);

      j++;
      p = p->next;
    }

    printf("\n");
    i++;
    c = c->next;
  }
}

void printPredicate(predicate* p) {
  printf("%s – ", p->id);
  if(p->first_var != NULL) {
    printVariables(p->first_var);
  }
}


void printVariables(var* head) {
  int i = 1;
  var* cursor = head;
  while(cursor->next != NULL) {
    printf("%d: %s, ", i, cursor->id);
    i++;
    cursor = cursor->next;
  }
  if(cursor != NULL) {
    printf("%d: %s", i, cursor->id);
  }
}

int main(void) {

  yyparse();
  printClauses();

  return 1;
}

void yyerror(const char* e) {
  printf("Error: %s\n", e);
}