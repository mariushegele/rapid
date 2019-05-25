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
  struct graph* graph;
} clause;

typedef struct edge {
  // node* from;
  struct node* dst;
  unsigned short lr; // 1 = L, 2 = R
  struct edge* next;
} edge;

typedef struct node {
  char type; // one of E, U, C, A, R, G, I
  struct edge* first_out;
  char* input; // for E, G, I
  int index;
  struct node* next;
} node;

typedef struct graph {
  node* entry;
  node* node_head;
} graph;


// clauses, predicates, variables
clause* create_clause();
clause* add_clause(clause*);

predicate* create_predicate();
predicate* add_predicate(predicate*, predicate*);

var* create_variable(char*);
void add_variable(var*);
var* shared_variables(var*, var*);
var* pred_shared_variables(predicate*, predicate*);
var* copy_variable(var*);
void append_variable(var*, var**);


void executeDependencyAnalysis(clause*, predicate*);
var* unconditionallyDependentVars(predicate*, predicate*, predicate*);
bool unconditionallyIndependent(predicate*, predicate*, predicate*);
var* varsToGroundTest(predicate*, predicate*, predicate*);
var* varsToIndependenceTest(predicate*, predicate*, predicate*);

bool strCmp(char*, char*);
void printClauses();
void printPredicate(predicate*);
void asPrintVariables(char**, var*);
void printVariables(var*);



// graphs, nodes and edges


// global pointer
clause* head_clause;
clause* current_clause;
predicate* current_predicate;

int clause_count = 0;
int node_count = 1;

graph* current_graph = NULL;
node* current_node = NULL;

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
    //new_pred->id = strdup($1); // a ( X, Y )
    asprintf(&(new_pred->id), "%s(%s)", $1, $4); // a ( X, Y )
    $$ = new_pred;
  }
  | PredMark Condition {
    printf(" %s ", $2);
    predicate* new_pred = $1;
    new_pred->id = strdup($2); // > (X, Y)
    $$ = new_pred;
   }
  | PredMark Assignment {
    printf(" %s ", $2);
    predicate* new_pred = $1;
    new_pred->id = strdup($2);
    $$ = new_pred;
  };

PredMark: { predicate* new_pred = create_predicate(); 
    current_predicate = new_pred;
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

    append_variable(v, &(current_predicate->first_var));
    //add_variable(v);
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
  c->graph = NULL;

  return c;
};

clause* add_clause(clause* c) {
  if(current_clause == NULL) {
    // List empty
    head_clause = c;
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
  v->id = id;
  v->next = NULL;
  
  return v;
};

var* pred_shared_variables(predicate* left, predicate* right) {
  return shared_variables(left->first_var, right->first_var);
}

var* shared_variables(var* left, var* right) {
  var* lcursor = left;
  var* rcursor = right;

  var* shared = NULL;
  while(lcursor != NULL) {
    rcursor = right;
    while(rcursor != NULL) {
      if(strcmp(lcursor->id, rcursor->id) == 0) {
          var* copy = copy_variable(lcursor);
          append_variable(copy, &shared);        
      }
      rcursor = rcursor->next;
    }
    lcursor = lcursor->next;
  }

  return shared;
}

var* diff_variables(var* base, var* compare) {
  var* diff_vars = NULL;

  for(var* base_cursor = base; base_cursor != NULL; base_cursor = base_cursor->next) {
    bool not_in_comp = true;
    for(var* comp_cursor = compare; comp_cursor != NULL; comp_cursor = comp_cursor->next) {
      if(strcmp(base_cursor->id, comp_cursor->id) == 0) {
        not_in_comp = false;
      }
    }

    if(not_in_comp) {
      var* copy = copy_variable(base_cursor);
      append_variable(copy, &diff_vars);
    }
  }

  return diff_vars;
}

var* copy_variable(var* src) {
  var* dst = create_variable(src->id);
  return dst;
}

void append_variable(var* new_var, var** head) {
  if(*head == NULL) {
    *head = new_var;
  } else {
    var* cursor = NULL;
    for(cursor = *head; cursor->next != NULL; cursor=cursor->next) {
      if(strcmp(cursor->id, new_var->id) == 0) {
        return; // only append variables that don't exist yet
      }
    } // iterate to the end
    // append...
    cursor->next = new_var;
  }
}


/**
  * Graphs, Nodes, Edges
  */

graph* create_graph() {
  graph* new_graph = malloc(sizeof(struct graph));
  new_graph->entry = NULL;

  // create global pointer
  current_graph = new_graph;
  current_node = current_graph->node_head;
  return new_graph;
}

node* create_node(char type) {
  node* new_node = malloc(sizeof(struct node));
  new_node->index = node_count;
  node_count++;
  new_node->type = type;
  new_node->first_out = NULL;
  new_node->next = NULL;

  // append to node list
  if(current_graph->node_head == NULL) {
    current_graph->node_head = new_node;
    current_node = current_graph->node_head;
  } else {
    current_node->next = new_node;
    current_node = current_node->next;
  }
  return new_node;
}

edge* create_edge(node* dst, unsigned short lr) {
  edge* new_edge = malloc(sizeof(struct edge));
  new_edge->dst = dst;
  new_edge->lr = lr;
  new_edge->next = NULL;
  return new_edge;
}

// connect the src node with the dst node's input l/r = 1/2
void connect(node* src, node* dst, unsigned short lr) {
  
  if(src->first_out == NULL) {
    src->first_out = create_edge(dst, lr);
  } else {
    edge* last_out = NULL;
    for(last_out = src->first_out; last_out->next != NULL; last_out = last_out->next) { } // iterate to end
    last_out->next = create_edge(dst, lr);
  }
}

void constructGraphs() {
  clause* c = head_clause;
  // iterate over all clauses
  while(c != NULL) {

    // create graph and entry node
    graph* graph = create_graph();

    node* entry_node = create_node('E');
    entry_node->input = c->head->id;
    graph->entry = entry_node;

    if(strcmp(c->type, "fact") == 0) {
      // simply return
      node* return_node = create_node('R');

      connect(entry_node, return_node, 1);
      
    } else if(strcmp(c->type, "rule") == 0) {

      node* update_entry_with_last_goal = NULL;
      node* copy_binding_env = NULL;
      node* last_copy_apply = NULL;


      int subgoal_count = 1;
      for(predicate* subgoal = c->first_subgoal;
          subgoal != NULL; 
          subgoal=subgoal->next, subgoal_count++) 
      {
        node* update_entry_with_goal = create_node('U');

        if(subgoal_count == 1) {
          // left of entry with right of subgoal goal update      
          connect(entry_node, update_entry_with_goal, 2);

          // right of entry distributes binding environment
          copy_binding_env = create_node('C');
          connect(entry_node, copy_binding_env, 1);
        } else {
          // starting from the second subgoal
          connect(update_entry_with_last_goal, update_entry_with_goal, 2);
        }

        update_entry_with_last_goal = update_entry_with_goal;

        node* update_subgoal_with_entry_binding = create_node('U');
        update_subgoal_with_entry_binding->input = subgoal->id;
        connect(copy_binding_env, update_subgoal_with_entry_binding, 1);

        if(subgoal_count == 1) {
          // first subgoal simply apply
          node* apply = create_node('A');
          connect(update_subgoal_with_entry_binding, apply, 1);

          if(subgoal->next == NULL) {
            connect(apply, update_entry_with_goal, 1);
          } else {
            // else copy out from apply because independence or ground test
            // could require update of previous subgoal with the new binding
            node* copy_apply = create_node('C');
            connect(apply, copy_apply, 1);
            last_copy_apply = copy_apply;
            connect(copy_apply, update_entry_with_goal, 1);
          }

        } else { // starting from the second subgoal...
          // execute dependency analysis
          // for all previous subgoals
          for(predicate* prev_subgoal = c->first_subgoal; prev_subgoal != subgoal; prev_subgoal = prev_subgoal->next) {
            
            // possibly unconditionally (in)dependent
            if(unconditionallyDependentVars(subgoal, prev_subgoal, c->head) != NULL) {
              printf("unconditionally dependent %s %s – ", subgoal->id, prev_subgoal->id);
              printVariables(unconditionallyDependentVars(subgoal, prev_subgoal, c->head));
              printf("\n");

              // first update with binding of previous subgoal...
              node* update_subgoal_with_prev_subgoal_binding = create_node('U');
              connect(update_subgoal_with_entry_binding, update_subgoal_with_prev_subgoal_binding, 2);
              connect(last_copy_apply, update_subgoal_with_prev_subgoal_binding, 1);

              // then apply and distribute...
              node* apply = create_node('A');
              connect(update_subgoal_with_prev_subgoal_binding, apply, 1);
              if(subgoal->next == NULL) {
                connect(apply, update_entry_with_goal, 1);
              } else {
                // else copy out from apply because independence or ground test
                // could require update of previous subgoal with the new binding
                node* copy_apply = create_node('C');
                connect(apply, copy_apply, 1);
                last_copy_apply = copy_apply;
                connect(copy_apply, update_entry_with_goal, 1);
              }

            } else if(unconditionallyIndependent(subgoal, prev_subgoal, c->head)) {
              printf("unconditionally independent %s %s \n", subgoal->id, prev_subgoal->id);
              // simply apply and distribute...
              node* apply = create_node('A');
              connect(update_subgoal_with_entry_binding, apply, 1);

              if(subgoal->next == NULL) {
                connect(apply, update_entry_with_goal, 1);
              } else {
                // else copy out from apply because independence or ground test
                // could require update of previous subgoal with the new binding
                node* copy_apply = create_node('C');
                connect(apply, copy_apply, 1);
                last_copy_apply = copy_apply;
                connect(copy_apply, update_entry_with_goal, 1);
              }

            } else {
              // neither unconditionally dependent nor independent -> variables to be ground/independence tested?

              node* update_subgoal_with_prev_subgoal_binding = create_node('U');
              node* apply = create_node('A');
              connect(last_copy_apply, update_subgoal_with_prev_subgoal_binding, 1);
              connect(update_subgoal_with_prev_subgoal_binding, apply, 1);

              node* ground_test;

              var* possibly_grounded = varsToGroundTest(subgoal, prev_subgoal, c->head);
              var* possibly_dependent = varsToIndependenceTest(subgoal, prev_subgoal, c->head);

              if(possibly_grounded != NULL) {
                // include ground test node
                printf("possibly grounded %s %s – ", subgoal->id, prev_subgoal->id);
                printVariables(possibly_grounded);
                printf("\n");

                ground_test = create_node('G');
                connect(update_subgoal_with_entry_binding, ground_test, 1);
                asPrintVariables(&ground_test->input, possibly_grounded);


                // left out of ground == failure == truly ground -> update with previous binding
                connect(ground_test, update_subgoal_with_prev_subgoal_binding, 2);
                
                if(possibly_dependent == NULL) {
                  // right of ground == success == not grounded -> just apply
                  connect(ground_test, apply, 1);
                } else {
                  // independence test coming...
                  // right of ground will be connected to I node                
                }
              }              

              if(possibly_dependent != NULL) {
                if(possibly_dependent->next != NULL) {
                  // include independence test node
                  printf("possibly dependent %s %s – ", subgoal->id, prev_subgoal->id);
                  printVariables(possibly_dependent);
                  printf("\n");

                  node* independence_test = create_node('I');
                  asPrintVariables(&independence_test->input, possibly_dependent);
                  asprintf(&independence_test->input, "[[%s]]", independence_test->input);

                  if(possibly_grounded != NULL) {
                    // both independence and ground test necessary -> connect ground to ind. test
                    connect(ground_test, independence_test, 1);
                  } else {
                    // only independence test
                    connect(update_subgoal_with_entry_binding, independence_test, 1);
                  }

                  // left out independence test == failure == not independent -> update with previous binding
                  connect(independence_test, update_subgoal_with_prev_subgoal_binding, 2);

                  // right of independence test == success == truly independent -> just apply
                  connect(independence_test, apply, 1);
                }
              }

              if(possibly_dependent == NULL && possibly_grounded == NULL) {
                printf("PROBLEM \n");
              }

              if(subgoal->next == NULL) {
                connect(apply, update_entry_with_goal, 1);
              } else {
                // else copy out from apply because independence or ground test
                // could require update of previous subgoal with the new binding
                node* copy_apply = create_node('C');
                connect(apply, copy_apply, 1);
                last_copy_apply = copy_apply;
                connect(copy_apply, update_entry_with_goal, 1);
              }
            }
          }
        }


      }

      // feed last updated environment into return
      node* return_node = create_node('R');
      connect(update_entry_with_last_goal, return_node, 1);

    } else {
      printf("unexpected rule/fact");
    }
    c->graph = graph;


    c = c->next;
  }
}

/*
* Dependeny Checks
*/

var* unconditionallyDependentVars(predicate* current, predicate* previous, predicate* head) {
  var* shared = pred_shared_variables(current, previous);
  var* in_head = pred_shared_variables(current, head);
  var* shared_not_in_head = diff_variables(shared, in_head);

  return shared_not_in_head;
}

bool unconditionallyIndependent(predicate* current, predicate* previous, predicate* head) {
  var* shared = pred_shared_variables(current, previous);
  var* in_head = pred_shared_variables(current, head);
  if(in_head == NULL && shared == NULL) {
    return true;
  } else {
    return false;
  }
}

var* varsToGroundTest(predicate* current, predicate* previous, predicate* head) {
  var* shared = pred_shared_variables(current, previous);
  var* in_head = pred_shared_variables(current, head);
  var* ground_test_vars = shared_variables(shared, in_head);

  return ground_test_vars;
}

var* varsToIndependenceTest(predicate* current, predicate* previous, predicate* head) {
  var* shared = pred_shared_variables(current, previous);
  var* this_in_head = pred_shared_variables(current, head);
  var* prev_in_head = pred_shared_variables(previous, head);

  var* this_in_head_not_shared = diff_variables(this_in_head, shared);
  var* prev_in_head_not_shared = diff_variables(prev_in_head, shared);

  // append all
  var* ind_test_vars = this_in_head_not_shared;

  for(var* pcursor = prev_in_head_not_shared; pcursor != NULL; pcursor=pcursor->next) {
    append_variable(pcursor, &ind_test_vars);
  }
  
  return ind_test_vars;
}




/**
  * Prints
  */

void printNode(node* node) {
  int printed = 0;

  printf("%d\t%c\t", node->index, node->type);
  if(node->first_out != NULL) {
    for(edge* edge_cursor = node->first_out;
      edge_cursor != NULL; edge_cursor = edge_cursor->next)
      {
        printf("(%d,%d)\t", edge_cursor->dst->index, edge_cursor->lr);
        printed++;
      }
  }

  while(printed < 2) {
    printf("-\t");
    printed++;
  }
  
  if(node->input != NULL) {
    printf("%s", node->input);
  }
  else {
    if(printed < 3) {
      printf("-");
    }
  }
  printf("\n");
}

void printGraphs() {
  clause* c = head_clause;
  while(c != NULL) {
    if(c->graph != NULL) {
      node* node_cursor = c->graph->node_head;
      while(node_cursor != NULL) {
        printNode(node_cursor);
        node_cursor = node_cursor->next;
      }
    }
    c = c->next;
  }
}

void printClauses() {
  int i = 1;
  clause* c = head_clause;
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
  var* cursor = head;
  if(cursor != NULL) {
    while(cursor->next != NULL) {
      printf("%s, ", cursor->id);
      cursor = cursor->next;
    }
    if(cursor != NULL) {
      printf("%s", cursor->id);
    }
  }
}

void asPrintVariables(char** target, var* head) {
  var* cursor = head;
  if(cursor != NULL) {
    while(cursor->next != NULL) {
      if(*target != NULL) {
        asprintf(target, "%s%s, ", *target, cursor->id);
      } else {
        asprintf(target, "%s, ", cursor->id);
      }
      cursor = cursor->next;
    }
    if(cursor != NULL) {
      if(*target != NULL) {
        asprintf(target, "%s%s", *target, cursor->id);
      } else {
        asprintf(target, "%s", cursor->id);
      }
    }
  }
}

int main(void) {

  yyparse();
  //printClauses();
  constructGraphs();
  printGraphs();

  clause* c = head_clause;
  predicate* l = c->first_subgoal;
  predicate* r = c->first_subgoal->next;

  var* first_shared = pred_shared_variables(l, r);
  var* shared_cursor = first_shared;
  while(shared_cursor != NULL) {
    shared_cursor = shared_cursor->next;
  }

  return 1;
}

void yyerror(const char* e) {
  printf("Error: %s\n", e);
}