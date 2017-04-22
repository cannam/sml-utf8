
SCRIPTS	:= ../sml-buildscripts

TESTFILES	:= testfiles/simple.txt testfiles/sampler.txt testfiles/emoji.txt

test:	process
	@for t in ${TESTFILES} ; do \
		./process $$t > test-out.txt ; \
		if diff $$t test-out.txt ; then echo Test $$t succeeded ; \
		else echo Test $$t failed ; \
		fi ; \
	done

timing:	process testfiles/long.txt
	time ./process testfiles/long.txt > test-out.txt

process: process.mlb d/process.deps
	mlton process.mlb

testfiles/long.txt:	testfiles/sampler.txt
	@cp $< tmp.txt; \
	for n in 2 4 8 16 32 64 128 256 512 1024 ; do \
		cat tmp.txt tmp.txt > tmp-out.txt ; \
		mv tmp-out.txt tmp.txt ; \
	done ; \
	mv tmp.txt $@ 

d/process.deps:	process.mlb
	${SCRIPTS}/mlb-dependencies $< > $@

coverage:
	${SCRIPTS}/mlb-coverage process.mlb testfiles/emoji.txt

clean:
	rm -f process d/*

-include d/*.deps
