%{
#include "rapid.tab.h"
%}

space [ \t]
%%

{space}*\:\-{space}* return left_arrow;
{space}+is{space}+ return is;

[A-Z_][a-zA-Z0-9_]* return variable;
[a-z][a-zA-Z0-9_]*|\'[.]+\' return atom;

\( return open_round_brackets;
\) return close_round_brackets;
\[ return open_square_brackets;
\] return close_square_brackets;
\. return dot;
{space}*\,{space}* return comma;

\%[.]*  return comment;
\*\/  return begin_multiline_comment;
\/\*  return end_multiline_comment;

\n  return end;
.  return undefined;


%%