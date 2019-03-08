%{
#include <stdio.h>
#include <math.h>
#include "rapid.tab.h"

#define YYERROR_VERBOSE 1

void yyerror(const char *);
int yylex();
%}

%token left_arrow is
%token atom variable
%token comment begin_multiline_comment end_multiline_comment 
%token open_round_brackets close_round_brackets
%token open_square_brackets close_square_brackets
%token dot comma
%token end undefined
%union {
  int integer;
  double reell;
  char* str;
}
%type <str> clause
%type <str> rule
%type <str> fact
%start S
%nonassoc left_arrow

%%

S : clause end { printf("=> %s \n\n", $1); }
clause : rule
  | fact
rule : predicate left_arrow predicate_list dot { $$="rule"}

predicate_list : predicate
  | predicate comma predicate_list

predicate : term
  | atom open_round_brackets term_list close_round_brackets

term_list : term
  | term comma term_list
term : atom
  | variable
  | function
  | list
function : atom open_round_brackets term_list close_round_brackets

list : open_square_brackets term_list close_square_brackets
  | open_square_brackets list close_square_brackets
  | open_square_brackets term_list comma list close_square_brackets

fact : predicate dot { $$="fact" }

%%

int main(void) {
  yyparse();
  return 0;
}

void yyerror(const char* e) {
  printf("Error: %s\n", e);
}
