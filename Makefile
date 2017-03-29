
SCRIPTS	:= ../sml-buildscripts

TESTFILES	:= testfiles/simple.txt testfiles/sampler.txt testfiles/emoji.txt

test:	process
	@for t in ${TESTFILES} ; do \
		./process $$t > test-out.txt ; \
		if diff $$t test-out.txt ; then echo Test $$t succeeded ; \
		else echo Test $$t failed ; \
		fi ; \
	done

process: process.mlb d/process.deps
	mlton process.mlb

d/process.deps:	process.mlb
	${SCRIPTS}/mlb-dependencies $< > $@

coverage:
	${SCRIPTS}/mlb-coverage process.mlb testfiles/emoji.txt

clean:
	rm -f process d/*

-include d/*.deps
