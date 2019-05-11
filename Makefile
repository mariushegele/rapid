%.yy.c: %.l
	flex -o $@ $<

%.tab.c: %.y
	bison -d --debug -t -v $<

%: %.tab.c %.yy.c
	gcc -Wall -ll -lm -g -o $@ $^
	rm $@.tab.h
	chmod u+x $@

