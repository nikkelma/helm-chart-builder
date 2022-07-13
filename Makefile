test_targets := $(shell ls test)

.PHONY: test
test:
	cd test/ && echo ${test_targets}
