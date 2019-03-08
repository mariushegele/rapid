%.yy.c: %.l
	flex -o $@ $<

%.tab.c: %.y
	bison -d $<

%: %.tab.c %.yy.c
	gcc -Wall -ll -lm -o $@ $^
	rm $@.tab.h
	chmod u+x $@

