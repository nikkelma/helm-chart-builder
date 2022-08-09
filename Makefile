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
	for d in ./tests/* ; do \
      pushd "$${d}"; \
      if [ -f ./ ]; then \
        ./scripts/test.sh ; \
      else \
        echo "$${d} does not contain scripts/test.sh" && exit 1; \
      fi \
      popd; \
    done
