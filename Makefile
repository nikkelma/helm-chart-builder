test_targets := $(shell ls tests)

.PHONY: test
test:
	cd tests/ && echo ${test_targets}
