%1 %unconditionally_dependent
a(X,Y) :- b(X,Z), c(Y,Z).
%2 %ground
a(X) :- b(X), c(X).
%3 %ground %poss_dependent
a(X,Y,Z) :- b(X,Y), c(X,Z).
%4 %poss_dependent
a(X,Y) :- b(X), c(Y).
%5 %uncond_independent
a(X) :- b(Y), c(Z).
%6 %poss_dep
a([A|B]) :- b(A), c(B).
%7 %poss_dep
a([A],[B]) :- b([[A]]), c([B]).
%8 %groundX %poss_dependent
a(X,Y,Z) :- b(X,Y), c(X,Z), d(X).

%9 %groundXY
a(X,Y) :- X>Y, X>=Y, X<Y, X=<Y, X = Y, X==Y, X\=Y, X\==Y.

%10 %uncond_independent
a(X,Y) :- b(5), c(5.117), 5 > X, d([5|T]).

%

ar(X,Y) :- X+Y>5.
ar(X,Y) :- a(X-Y).
ar(X,Y) :- X*Y>5.
%groundXY
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

p(X,Y):-q(X,Z),r(Z),s(Y,Z),t(Y),u(X,Y,Z).