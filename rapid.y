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
  char* id;
  char* full_id;
  var* first_var;
  struct predicate* next;
  struct node* apply_copy_node;
} predicate;

typedef struct clause {
  char *type; // rule or fact
  predicate* head;
  predicate* first_subgoal;
  struct clause* next;
  struct graph* graph;
} clause;

typedef struct pred_group {
  struct clause* clauses;
  char* id;
  int num_args;
  struct pred_group* next;
} pred_group;

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
  struct node* next_last_in_stream;
} node;

typedef struct graph {
  node* entry;
  node* node_head;
} graph;


// clauses, predicates, variables
clause* create_clause();
void insert_clause(clause*, pred_group**);

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

void printNode(node*);
void fprintNode(node*, FILE**);
void printGraphs();
void writeGraphs();


// global pointer
pred_group* grouped_clauses = NULL;

var* current_variables = NULL;

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

%type<pred> Predicate PredicateList

%start S

%left smaller greater equal

%left plus minus
%left times divby


%%

S: Clause { insert_clause($1, &grouped_clauses); }
  | S Clause { insert_clause($2, &grouped_clauses); }
  | S Comment;
  | Comment;
  | S end;
  | end;

Clause: Rule { 
  $1->type = "rule";
  $$ = $1;
 }
  | Fact { 
    $1->type = "fact";
    $$ = $1; 
  };

Rule: Predicate left_arrow PredicateList dot {
    clause* new_clause = create_clause();
    new_clause->head = $1;
    new_clause->first_subgoal = $3;
    $$ = new_clause;
  };

Fact: Predicate dot {
    clause* new_clause = create_clause();
    new_clause->head = $1;
    new_clause->first_subgoal = NULL;
    $$ = new_clause;
  };

PredicateList: Predicate { 
    $$ = $1;
  }
  | Predicate comma PredicateList { 
      predicate* head = $1;
      head->next = $3;
      $$ = head;      
  };

Predicate: atom open_round_brackets TermList close_round_brackets {
    predicate* new_predicate = create_predicate();
    asprintf(&(new_predicate->full_id), "%s(%s)", $1, $3); // a ( X, Y )
    asprintf(&(new_predicate->id), "%s", $1); // a 
    new_predicate->first_var = current_variables;
    current_variables = NULL;

    $$ = new_predicate;
  }
  | Condition {
    predicate* new_predicate = create_predicate();
    new_predicate->id = $1;
    new_predicate->full_id = $1;
    new_predicate->first_var = current_variables;
    current_variables = NULL;

    $$ = new_predicate;
   }
  | Assignment {
    predicate* new_predicate = create_predicate();
    new_predicate->id = $1;
    new_predicate->full_id = $1;
    new_predicate->first_var = current_variables;
    current_variables = NULL;

    $$ = new_predicate;
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

    append_variable(v, &current_variables);
    //add_variable(v);
    $$ = v->id;
  }
  | Operation { $$ = $1; }
  | Constant { $$ = $1; };

Constant: num { $$ = $1; }
  | real  
 
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
  c->type = NULL;
  c->next = NULL;
  c->graph = NULL;
  c->head = NULL;
  c->first_subgoal = NULL;
  return c;
};

int num_of_args(var* head) {
  int count = 0;
  for(var* var_cursor = head; var_cursor != NULL; var_cursor=var_cursor->next) {
    count++;
  }
  return count;
};

pred_group* create_group(clause* clause) {
  // create a group based on a clause
  pred_group* group = malloc(sizeof(struct pred_group));
  group->id = clause->head->id;
  
  // determine number of arguments
  group->num_args = num_of_args(clause->head->first_var);
  group->clauses = clause;
  group->next = NULL;

  return group;
}

bool is_in_group(clause* c, pred_group* group) {
  int num_args = num_of_args(c->head->first_var);
  return ( strcmp(c->head->id, group->id) == 0 ) && ( group->num_args == num_args );
}

clause* append_clause(clause* new_clause, clause** head) {
  if(*head == NULL) {
    *head = new_clause;
  } else {
    clause* cursor = NULL;
    for(cursor = *head; cursor->next != NULL; cursor=cursor->next) { } // iterate to the end
    // append...
    cursor->next = new_clause;
  }
  return new_clause;
}

void insert_clause(clause* new_clause, pred_group** head) {
  if(*head == NULL) {
    *head = create_group(new_clause);
    return;
  }

  pred_group* group_cursor;

  for(group_cursor = *head;
      group_cursor->next != NULL;
      group_cursor = group_cursor->next) { 
        if(is_in_group(new_clause, group_cursor)) {
          // append into group
          append_clause(new_clause, &group_cursor->clauses);
          return;
        }
      }
  
  group_cursor->next = create_group(new_clause);
}



predicate* create_predicate() {
  predicate* p = malloc(sizeof(struct predicate));
  p->id = NULL;
  p->full_id = NULL;
  p->first_var = NULL;
  p->next = NULL;
  p->apply_copy_node = NULL;
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
  new_graph->node_head = NULL;

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
  new_node->input = NULL;
  new_node->first_out = NULL;
  new_node->next = NULL;
  new_node->next_last_in_stream = NULL;

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

void append_node_to(node* new_node, node** head) {
  if(*head == NULL) {
    *head = new_node;
  } else {
    node* cursor = NULL;
    for(cursor = *head; cursor->next_last_in_stream != NULL; cursor=cursor->next_last_in_stream) {} // iterate to the end
    // append...
    cursor->next_last_in_stream = new_node;
  }
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

void connect_all_to(node* node_list, node* dst, unsigned short lr) {
  for(node* cursor = node_list; cursor != NULL; cursor = cursor->next_last_in_stream) {
    connect(cursor, dst, lr);
  }
}

/**
* Where the magic happens – construct a graph for each clause in the symbol table
*/
void constructGraphs() {
  for(pred_group* group = grouped_clauses;
      group != NULL; group = group->next)
    {
      clause* c = group->clauses;
      // iterate over all clauses
      while(c != NULL) {

        // create graph and entry node
        graph* graph = create_graph();

        node* entry_node = create_node('E');
        entry_node->input = c->head->full_id;
        graph->entry = entry_node;

        if(strcmp(c->type, "fact") == 0) {
          // simply return
          node* return_node = create_node('R');

          connect(entry_node, return_node, 1);
          
        } else if(strcmp(c->type, "rule") == 0) {

          node* update_entry_with_last_goal = NULL;
          node* copy_binding_env = NULL;
          node* last_in_stream; // list of nodes that are "last in the stream" -> to be applied


          int subgoal_count = 1;
          for(predicate* subgoal = c->first_subgoal;
              subgoal != NULL; 
              subgoal=subgoal->next, subgoal_count++) 
          {
            node* update_entry_with_goal = create_node('U');

            if(subgoal_count == 1) {
              // left of entry with right of subgoal goal update      
          // left of entry with right of subgoal goal update      
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
            update_subgoal_with_entry_binding->input = subgoal->full_id;
            last_in_stream = update_subgoal_with_entry_binding;
            connect(copy_binding_env, update_subgoal_with_entry_binding, 1);


            node* apply; // the final goal: an apply node

            if(subgoal_count > 1) {  // starting from the second subgoal...
              
              // execute dependency analysis
              // for all previous subgoals

              printf("\npredicate: %s \n", subgoal->full_id);
              
              for(predicate* prev_subgoal = c->first_subgoal; prev_subgoal != subgoal; prev_subgoal = prev_subgoal->next) {
                
                // possibly unconditionally (in)dependent
                if(unconditionallyDependentVars(subgoal, prev_subgoal, c->head) != NULL) {
                  printf("unconditionally dependent %s %s – ", subgoal->full_id, prev_subgoal->full_id);
                  printVariables(unconditionallyDependentVars(subgoal, prev_subgoal, c->head));
                  printf("\n");

                  // first update with binding of previous subgoal...
                  node* update_subgoal_with_prev_subgoal_binding = create_node('U');
                  connect_all_to(last_in_stream, update_subgoal_with_prev_subgoal_binding, 2);
                  connect(prev_subgoal->apply_copy_node, update_subgoal_with_prev_subgoal_binding, 1);

                  last_in_stream = update_subgoal_with_prev_subgoal_binding;
                  
                } else if(unconditionallyIndependent(subgoal, prev_subgoal, c->head)) {
                  printf("unconditionally independent %s %s \n", subgoal->full_id, prev_subgoal->full_id);
                  // nothing to be done

                } else {
                  // neither unconditionally dependent nor independent -> variables to be ground/independence tested?

                  node* update_subgoal_with_prev_subgoal_binding = create_node('U');
                  connect(prev_subgoal->apply_copy_node, update_subgoal_with_prev_subgoal_binding, 1);

                  node* ground_test;

                  var* possibly_grounded = varsToGroundTest(subgoal, prev_subgoal, c->head);
                  var* possibly_dependent = varsToIndependenceTest(subgoal, prev_subgoal, c->head);

                  if(possibly_grounded != NULL) {
                    // include ground test node
                    printf("possibly grounded %s %s – ", subgoal->full_id, prev_subgoal->full_id);
                    printVariables(possibly_grounded);
                    printf("\n");

                    ground_test = create_node('G');
                    asPrintVariables(&ground_test->input, possibly_grounded);
                    
                    connect_all_to(last_in_stream, ground_test, 1);

                    // left out of ground == failure == truly ground -> update with previous binding
                    connect(ground_test, update_subgoal_with_prev_subgoal_binding, 2);
                    
                    // right of ground == success == not grounded -> will be forwarded to apply or next test
                    last_in_stream = ground_test;
                    ground_test->next_last_in_stream = update_subgoal_with_prev_subgoal_binding;
                  }                               

                  if(possibly_dependent != NULL) {
                    if(possibly_dependent->next != NULL) {
                      // include independence test node
                      printf("possibly dependent %s %s – ", subgoal->full_id, prev_subgoal->full_id);
                      printVariables(possibly_dependent);
                      printf("\n");

                      node* independence_test = create_node('I');
                      asPrintVariables(&independence_test->input, possibly_dependent);
                      asprintf(&independence_test->input, "[[%s]]", independence_test->input);

                      if(possibly_grounded) {
                        connect(last_in_stream, independence_test, 1);
                      } else {
                        connect_all_to(last_in_stream, independence_test, 1);
                      }

                      // left out independence test == failure == not independent -> update with previous binding
                      connect(independence_test, update_subgoal_with_prev_subgoal_binding, 2);

                      // right of independence test == success == truly independent -> will be forwarded to apply or next test
                      last_in_stream = independence_test;
                      last_in_stream->next_last_in_stream = update_subgoal_with_prev_subgoal_binding;

                    }
                  }

                  if(possibly_dependent == NULL && possibly_grounded == NULL) {
                    printf("PROBLEM \n");
                  }
                }
              }

            }

            // finally apply
            apply = create_node('A');
            connect_all_to(last_in_stream, apply, 1);

            // finally update the entry distribution with the applied subgoal's binding
            if(subgoal->next == NULL) {
              connect(apply, update_entry_with_goal, 1);
            } else {
              // else copy out from apply because independence or ground test
              // could require update of previous subgoal with the new binding
              node* copy_apply = create_node('C');
              connect(apply, copy_apply, 1);
              subgoal->apply_copy_node = copy_apply;
              connect(copy_apply, update_entry_with_goal, 1);
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

  var* this_in_head = pred_shared_variables(current, head);
  var* prev_in_head = pred_shared_variables(previous, head);

  var* shared_in_head = shared_variables(shared, this_in_head);
  var* this_in_head_not_shared = diff_variables(this_in_head, shared);
  var* prev_in_head_not_shared = diff_variables(prev_in_head, shared);

  if(shared_in_head == NULL && (this_in_head_not_shared == NULL || prev_in_head_not_shared == NULL)) {
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

void fprintNode(node* node, FILE** f) {
  int printed = 0;

  fprintf(*f, "%d\t%c\t", node->index, node->type);
  if(node->first_out != NULL) {
    for(edge* edge_cursor = node->first_out;
      edge_cursor != NULL; edge_cursor = edge_cursor->next)
      {
        fprintf(*f, "(%d,%d)\t", edge_cursor->dst->index, edge_cursor->lr);
        printed++;
      }
  }

  while(printed < 2) {
    fprintf(*f, "-\t");
    printed++;
  }
  
  if(node->input != NULL) {
    fprintf(*f, "%s", node->input);
  }
  else {
    if(printed < 3) {
      fprintf(*f, "-");
    }
  }
  fprintf(*f, "\n");
}

void printGraphs() {
  for(pred_group* group = grouped_clauses; group != NULL; group = group->next) {
    clause* c = group->clauses;
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
}

void writeGraphs() {
  FILE *f = fopen("graphs.txt", "w");
  if (f == NULL) {
    printf("Error opening file!\n");
    return;
  }

  for(pred_group* group = grouped_clauses; group != NULL; group = group->next) {
    clause* c = group->clauses;
    while(c != NULL) {
      if(c->graph != NULL) {
        node* node_cursor = c->graph->node_head;
        while(node_cursor != NULL) {
          fprintNode(node_cursor, &f);
          node_cursor = node_cursor->next;
        }
      }
      c = c->next;
    }
  }

  fclose(f);
}

void printClauses() {
  for(pred_group* group = grouped_clauses; group != NULL; group=group->next) {
    printf("Predicate %s with number of arguments: %d\n", group->id, group->num_args);
    int i = 1;
    clause* c = group->clauses;
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
    printf("\n");
  }
}

void printPredicate(predicate* p) {
  printf("%s – ", p->full_id);
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
  printClauses();
  constructGraphs();
  printGraphs();
  writeGraphs();

  return 1;
}

void yyerror(const char* e) {
  printf("Error: %s\n", e);
}