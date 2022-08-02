SHELL=/bin/bash

test_targets := $(shell ls tests)

.PHONY: build-tests
build-tests:
	for d in ./tests/* ; do \
      pushd "$${d}"; \
	  [ -f ./scripts/build.sh ] && ./scripts/build.sh ; \
      popd; \
    done

.PHONY: test
test:
	cd tests/ && echo ${test_targets}
