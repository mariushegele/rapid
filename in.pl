%1
a(X,Y) :- b(X,Z), c(Y,Z).
%2
a(X) :- b(X), c(X).
%3
a(X,Y,Z) :- b(X,Y), c(X,Z).
%4
a(X,Y) :- b(X), c(Y).
%5
a(X) :- b(Y), c(Z).
%6
a([A|B]) :- b(A), c(B).
%7
a([A],[B]) :- b([[A]]), c([B]).
%8
a(X,Y,Z) :- b(X,Y), c(X,Z), d(X).

%9
a(X,Y) :- X>Y, X>=Y, X<Y, X=<Y, X = Y, X==Y, X\=Y, X\==Y.

%10
a(X,Y) :- b(5), c(5.117), 5 > X, d([5|T]).

%

ar(X,Y) :- X+Y>5.
ar(X,Y) :- a(X-Y).
ar(X,Y) :- X*Y>5.
ar(X,Y) :- a(X/Y), b(X+Y*X).
ar(X,Y) :- X+Y*X>5.
ar(X,Y) :- X-Y/X>5.
ar(X,Y) :- X*Y/X>5.
ar(X,Y) :- (X+Y)*X>5.

ar(X,Y) :- X is Y.
ar(X, Y) :- X is Y-1.
ar(X, Y) :- X is Y+1.
ar(X, Y) :- X is Y*1.
ar(X, Y) :- X is Y/1.


a(X) :- b(b(b([A|B]))).

b(A,A).
c(A,A).
