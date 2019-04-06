%{
#include "rapid.tab.h"
%}

%option nounput
%option noinput

%%

[ \t] // ignore space

\:\- return left_arrow;
is return is;

[A-Z_][a-zA-Z0-9_]* {
    yylval.str = strdup(yytext);
    return variable;
}

[a-z][a-zA-Z0-9_]*|\'[.]+\' {
    yylval.str = strdup(yytext);
    return atom;
}

[0-9]+ {
    sscanf(yytext, "%d", &yylval.integer);
    return number;
}
[0-9]+.[0-9]+ {
    sscanf(yytext, "%lf", &yylval.real); 
    return rnum;
}
\"[a-zA-Z0-9]*\" return string;

\( return open_round_brackets;
\) return close_round_brackets;
\[ return open_square_brackets;
\] return close_square_brackets;
\| return pipesym;
\, return comma;

\< return smaller;
\> return greater;
\= return equal;
\\ return whatthehell;

\+ return plus;
\- return minus;
\* return times;
\/ return divby;


\%.* return comment;
\/\*.*\*\/  return ml_comment;

\. return dot;
[\r\n|\n]  return end;
.  return undefined;

%%