
TESTFILES	:= simple.txt sampler.txt emoji.txt

test:	test.mlb simple-wide-string.sml simple-wide-string.sig test.sml main.sml
	mlton test.mlb
	@for t in ${TESTFILES} ; do \
		./test $$t > test-out.txt ; \
		if diff $$t test-out.txt ; then echo Test $$t succeeded ; \
		else echo Test $$t failed ; \
		fi ; \
	done

clean:
	rm -f test
