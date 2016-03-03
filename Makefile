
TESTFILES	:= testfiles/simple.txt testfiles/sampler.txt testfiles/emoji.txt

test:	process
	@for t in ${TESTFILES} ; do \
		./process $$t > test-out.txt ; \
		if diff $$t test-out.txt ; then echo Test $$t succeeded ; \
		else echo Test $$t failed ; \
		fi ; \
	done

process: process.mlb simple-wide-string.sml simple-wide-string.sig process.sml main.sml
	mlton process.mlb

clean:
	rm -f process
