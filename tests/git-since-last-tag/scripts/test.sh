#!/bin/bash

# function signature: clean_artifact_dir [directory]
clean_artifact_dir() {
  target_dir="/opt/nikkelma/helm-chart-builder/artifacts/"
  if [[ -n "${1}" ]]; then
    target_dir="${1}"
  fi

  rm -rf "${target_dir:?}"/*
}

# function signature: [directory=<directory>] check_folder_files <file> [file...]
check_folder_files() {
  target_dir="/opt/nikkelma/helm-chart-builder/artifacts/.hcb-package/"
  if [[ -n ${directory} ]]; then
    target_dir="${directory}"
  fi

  local found_file_count
  found_file_count="$(find "${target_dir}" -mindepth 1 -type f | wc -l)"

  if [[ ${found_file_count} -ne $# ]]; then
    echo "unexpected file count: got ${found_file_count}, expected $#"
    return 1
  fi

  local missing_file=0
  for f in "$@" ; do
    if [[ ! -f "${target_dir}/${f}" ]]; then
      echo "unexpected missing file ${target_dir}/${f}"
      missing_file=1
    fi
  done

  return ${missing_file}
}

main() {
  pushd repo-tree 1>&2 || {
    echo "failed changing to repo directory; exiting" 1>&2
    exit 1
  }

  local failed=0

  echo "---"

  echo "running test: should package single chart with no previous tags"
  git checkout test-1-1 1>&2
  hcb.sh --charts-depth=2 1>&2
  { check_folder_files nginx-test-a-1.0.0.tgz; echo "passed"; } || { failed=1; echo "failed"; }
  clean_artifact_dir
  echo "---"

  echo "running test: should package single chart with tag on previous commit"
  git checkout test-1-2 1>&2
  hcb.sh --charts-depth=2 1>&2
  { check_folder_files nginx-test-a-1.0.1.tgz; echo "passed"; } || { failed=1; echo "failed"; }
  clean_artifact_dir
  echo "---"

  echo "running test: should package single chart with tag on previous commit in non-default directory"
  git checkout test-1-3 1>&2
  mkdir -p /tmp/package-out 1>&2
  hcb.sh --charts-depth=2 --package-out /tmp/package-out 1>&2
  { directory="/tmp/package-out" check_folder_files nginx-test-b-1.0.0.tgz; echo "passed"; } || { failed=1; echo "failed"; }
  clean_artifact_dir "/tmp/package-out"
  rm -rf "/tmp/package-out"
  echo "---"

  if [[ $failed -ne 0 ]]; then
    echo "FAIL: single-chart tests failed; exiting"
    exit 1
  fi

  echo "should package multiple charts with no previous tags"
  git checkout test-3-1 1>&2
  hcb.sh --charts-depth=2 1>&2
  { check_folder_files nginx-test-a-1.0.0.tgz nginx-test-a-1.0.1.tgz; echo "passed"; } || { failed=1; echo "failed"; }
  clean_artifact_dir
  echo "---"

  echo "should package multiple charts with with tag on previous commit"
  git checkout test-3-2 1>&2
  hcb.sh --charts-depth=2 1>&2
  { check_folder_files nginx-test-b-1.0.0.tgz nginx-test-b-1.0.1.tgz; echo "passed"; } || { failed=1; echo "failed"; }
  clean_artifact_dir
  echo "---"

  if [[ $failed -ne 0 ]]; then
    echo "FAIL: multi-chart tests failed; exiting"
    exit 1
  fi

  popd 1>&2 || {
    echo "failed changing to original directory; exiting" 1>&2
    exit 1
  }
}

main
