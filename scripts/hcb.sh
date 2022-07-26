#!/bin/bash

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

usage() {
# inspired by / copied from https://github.com/helm/chart-releaser-action/blob/main/cr.sh
cat <<EOF
Usage: $(basename "$0") [options]

  -h, --help           Display help
      --repo-root      Location of git repo's root repository (override default auto-detection)
      --charts-dir     Base directory containing all charts (default: charts)
      --charts-depth   How many subdirectories deep to search for charts (default: 1)
      --package-out    Base directory for generated Helm package directory ".hcb-package"
                         (default: /opt/nikkelma/helm-chart-builder/artifacts/)
      --index-out      Base directory for generated index file ".hcb-index"
                         (default: /opt/nikkelma/helm-chart-builder/artifacts/)
EOF
# TODO - support more targets than "last-tag"
#      --since-kind     Kind of target (default: last-tag - options: last-tag, tag, commit, branch)
#                         > values "tag", "commit", "branch" require flag --since-target
#      --since-target   Target id/name for diff, if required (commit id, tag name, branch name)
#EOF
}

main() {
  # define available options
  local opts_short="h"
  local opts_long="help,repo-root:,charts-dir:,charts-depth:,package-out:,index-out:"
#  local opts_long="help,repo-root:,charts-dir:,charts-depth:,package-out:,index-out:,since-target:,since-kind:"

  local parsed_opts
  # parse options, allow side effects even on failure
  if ! parsed_opts=$(getopt --options "${opts_short}" --longoptions "${opts_long}" --name "$0" -- "$@") ; then
    usage
    exit 1
  fi

  # set the parsed arguments as the arguments for the current invocation context
  eval set -- "${parsed_opts}"

  # define which variables will be used to store resulting values
  local repo_root
  local charts_dir="charts"
  local charts_depth="1"
  local artifact_base_dir="/opt/nikkelma/helm-chart-builder/artifacts/"
  local since_kind="last-tag"
  local since_target

  # parse flags, storing values and shifting arguments as needed
  while true; do
    case "$1" in
    -h | --help)
      usage
      exit
      ;;
    --repo-root)
      if [[ -n "${2:-}" ]]; then
        repo_root="$2"
        shift 2
      else
        echo "ERROR: '--repo-root' cannot be empty." >&2
        usage
        exit 1
      fi
      ;;
    --charts-dir)
      if [[ -n "${2:-}" ]]; then
        charts_dir="$2"
        shift 2
      else
        echo "ERROR: '--charts-dir' cannot be empty." >&2
        usage
        exit 1
      fi
      ;;
    --charts-depth)
      if [[ -n "${2:-}" ]]; then
        charts_depth="$2"
        shift 2
      else
        echo "ERROR: '--charts-depth' cannot be empty." >&2
        usage
        exit 1
      fi
      ;;
#    --since-kind)
#      if [[ -n "${2:-}" ]]; then
#        since_kind="$2"
#        shift 2
#      else
#        echo "ERROR: '--since-kind' cannot be empty." >&2
#        usage
#        exit 1
#      fi
#      ;;
#    --since-target)
#      if [[ -n "${2:-}" ]]; then
#        since_target="$2"
#        shift 2
#      else
#        echo "ERROR: '--since-target' cannot be empty." >&2
#        usage
#        exit 1
#      fi
#      ;;
    --)
      shift
      break
      ;;
    *)
      # ideally this case should never happen, as getopt should have thrown an
      # error; just in case, handle the bad case and print usage
      echo "Unexpected option: $1"
      usage
      exit 1
      ;;
    esac
  done

  if [[ -z "${repo_root}" ]]; then
    repo_root=$(git rev-parse --show-toplevel)
  fi

  local latest_tag
  {
    prev_commit="$(git rev-parse HEAD~1)" && \
    latest_tag="$(lookup_latest_tag "${prev_commit}")"
  } || {
    latest_tag="$(lookup_latest_tag)"
  }

  echo "Discovering changed charts since '$latest_tag'..."
  local changed_charts=()
  readarray -t changed_charts <<< "$(lookup_changed_charts "${latest_tag}" "${charts_depth}")"

  if [[ -n "${changed_charts[*]}" ]]; then
    rm -rf "${artifact_base_dir}/.hcb-package" "${artifact_base_dir}/.hcb-index"
    mkdir -p "${artifact_base_dir}/.hcb-package" "${artifact_base_dir}/.hcb-index"

    for chart in "${changed_charts[@]}"; do
      if [[ -d "$chart" ]]; then
        artifact_base_dir="${artifact_base_dir}" package_chart "$chart"
      else
        echo "Chart '$chart' no longer exists in repo. Skipping it..."
      fi
    done
  else
    echo "Nothing to do. No chart changes detected."
  fi
}

# https://github.com/helm/chart-releaser-action/blob/main/cr.sh
# function signature: lookup_latest_tag [target_commit]
lookup_latest_tag() {
  target_commit="$1"
  if [[ -z "${target_commit}" ]]; then
    target_commit="$(git rev-parse HEAD)"
  fi

  git fetch --tags > /dev/null 2>&1
  if ! git describe --tags --abbrev=0 "${target_commit}" 2> /dev/null; then
    git rev-list --max-parents=0 --first-parent HEAD
  fi
}

# https://github.com/helm/chart-releaser-action/blob/main/cr.sh
filter_charts() {
  while read -r chart; do
    [[ ! -d "$chart" ]] && continue
    local file="$chart/Chart.yaml"
    if [[ -f "$file" ]]; then
      echo "$chart"
    else
      echo "WARNING: $file is missing, assuming that '$chart' is not a Helm chart. Skipping." 1>&2
    fi
  done
}

# https://github.com/helm/chart-releaser-action/blob/main/cr.sh
# function signature: lookup_changed_charts <commit> <charts_depth>
lookup_changed_charts() {
  local commit="$1"
  local charts_depth="$2"

  local changed_files
  changed_files=$(git diff --find-renames --name-only "$commit" -- "$charts_dir")

  local depth=$(( $(tr "/" "\n" <<< "$charts_dir" | sed '/^\(\.\)*$/d' | wc -l) + "${charts_depth}" ))
  local fields="1-${depth}"

  cut -d '/' -f "$fields" <<< "$changed_files" | uniq | filter_charts
}

# https://github.com/helm/chart-releaser-action/blob/main/cr.sh
# function signature: [config=<config>] package_chart <chart>
package_chart() {
  local chart="$1"

  local args=("$chart" --package-path .cr-release-packages)
  if [[ -n "$config" ]]; then
    args+=(--config "$config")
  fi

  echo "Packaging chart '$chart'..."
  cr package "${args[@]}"
}

main "$@"
