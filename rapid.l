%{
#include "rapid.tab.h"
%}

%option nounput
%option noinput

num [1-9][0-9]*|0
real {num}\.[0-9]+

%%

[ \t] // ignore space

\:\- return left_arrow;
is return is;

[A-Z_][a-zA-Z0-9_]* {
    yylval.str = strdup(yytext);
    return variable;
}

[a-z][a-zA-Z0-9_]* {
    yylval.str = strdup(yytext);
    return atom;
}

{num} {
    yylval.str = strdup(yytext);
    return num;
}

{real} {
    yylval.str = strdup(yytext);
    return real;
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
\: return colon;
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