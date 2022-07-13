#!/bin/bash

if [ -z "${REPO_DIR}" ]; then
  REPO_DIR="repo-tree"
fi

cd "${REPO_DIR}" || {
  echo "cd ${REPO_DIR} failed; exiting"
  exit 1
}

git config --global user.email "helm-chart-builder@localhost"
git config --global user.name "Helm Chart Builder"

git init
git branch -m main

git add README.md
git commit -m "Initial commit"

initial_commit_id="$(git rev-parse HEAD)"

# test 1
git branch main-test-1
git switch main-test-1

git add charts/nginx-test-a/1.0.0
git commit -m "Test 1 stage 1: Add chart A v1.0.0"
git tag test-1-1

git add charts/nginx-test-a/1.0.1
git commit -m "Test 1 stage 2: Add chart A v1.0.1"
git tag test-1-2

git add charts/nginx-test-b/1.0.0
git commit -m "Test 1 stage 3: Add chart B v1.0.0"
git tag test-1-3

git add charts/nginx-test-b/1.0.1
git commit -m "Test 1 stage 4: Add chart B v1.0.1"
git tag test-1-4

# test 2
git branch main-test-2
git switch main-test-2
git reset "${initial_commit_id}"

git add charts/nginx-test-a/
git commit -m "Test 2 stage 1: Add chart A v1.0.0 + v1.0.1"
git tag test-2-1

git add charts/nginx-test-b/1.0.0
git commit -m "Test 2 stage 2: Add chart B v1.0.0"
git tag test-2-2

git add charts/nginx-test-b/1.0.1
git commit -m "Test 2 stage 3: Add chart B v1.0.1"
git tag test-2-3

# test 3
git branch main-test-3
git switch main-test-3
git reset "${initial_commit_id}"

git add charts/nginx-test-a/
git commit -m "Test 3 stage 1: Add chart A v1.0.0 + v1.0.1"
git tag test-3-1

git add charts/nginx-test-b/
git commit -m "Test 3 stage 2: Add chart B v1.0.0 + v1.0.1"
git tag test-3-2

# test 4
git branch main-test-4
git switch main-test-4
git reset "${initial_commit_id}"

git add charts/nginx-test-a/1.0.0
git commit -m "Test 4 stage 1: Add chart A v1.0.0"

git add charts/nginx-test-a/1.0.1
git commit -m "Test 4 stage 2: Add chart A v1.0.1"
git tag test-4-2

git add charts/nginx-test-b/1.0.0
git commit -m "Test 4 stage 3: Add chart B v1.0.0"

git add charts/nginx-test-b/1.0.1
git commit -m "Test 4 stage 4: Add chart B v1.0.1"
git tag test-4-4
