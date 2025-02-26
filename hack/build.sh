#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# This script builds go components.
# You can set the platform to build with BUILD_PLATFORMS, with format: `<os>/<arch>`
# And binaries will be put in `_output/<os>/<arch>/`
#
# Usage:
#   hack/build.sh <target>
# Args:
#   $1:              target to build
# Environments:
#   BUILD_PLATFORMS: platforms to build. You can set one or more platforms separated by comma.
#                    e.g.: linux/amd64,linux/arm64
#   LDFLAGS          pass to the `-ldflags` parameter of go build
# Examples:
#   hack/build.sh clusterlink-controllermanager
#   BUILD_PLATFORMS=linux/amd64,linux/arm64 hack/build.sh clusterlink-controllermanager

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${REPO_ROOT}/hack/util.sh"

LDFLAGS="$(util::version_ldflags) ${LDFLAGS:-}"

function build_binary() {
  local -r target=$1

  IFS="," read -ra platforms <<< "${BUILD_PLATFORMS:-}"
  if [[ ${#platforms[@]} -eq 0 ]]; then
    platforms=("$(util:host_platform)")
  fi

  for platform in "${platforms[@]}"; do
    echo "!!! Building ${target} for ${platform}:"
    build_binary_for_platform "${target}" "${platform}"
  done
}

function build_binary_for_platform() {
  local -r target=$1
  local -r platform=$2
  local -r os=${platform%/*}
  local -r arch=${platform##*/}

  local target_pkg="${KOSMOS_GO_PACKAGE}/$(util::get_target_source "$target")"
  set -x
  CGO_ENABLED=0 GOOS=${os} GOARCH=${arch} go build \
      -ldflags "${LDFLAGS:-}" \
      -o "_output/bin/${platform}/$target" \
      "${target_pkg}"
  set +x

  if [[ "${target}" == "clusterlink-floater" ]]; then
    cp -r "cmd/clusterlink/floater/certificate" "_output/bin/${platform}/"
  fi
}

build_binary "$@"
