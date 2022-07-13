# Git repo - test `since-last-tag` helm chart build

This directory is intended to be used for testing `helm-chart-builder`'s "since last tag" packaging functionality.

## Tests

### Test 1
Start with one chart, add another version of the same chart, add multiple versions of another chart, all commits tagged.

1. Add chart A v1.0.0
2. Add chart A v1.0.1
3. Add chart B v1.0.0
4. Add chart B v1.0.1

### Test 2
Start with two different charts, add a version of one chart, add a version of the second chart, all commits tagged.

1. Add chart A v1.0.0 + chart B v1.0.0
2. Add chart A v1.0.1
3. Add chart B v1.0.1

### Test 3
Start with two different charts, add new versions of each chart in the same commit, all commits tagged.

1. Add chart A v1.0.0 + chart B v1.0.0
2. Add chart A v1.0.1 + chart B v1.0.1

### Test 4

Start with one chart, add another version of the same chart, add multiple versions of another chart; testing no "previous" tag, untagged third commit.

1. Add chart A v1.0.0 
2. Add chart A v1.0.1 - tagged
3. Add chart B v1.0.0
4. Add chart B v1.0.1 - tagged
