#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

set -exu

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

BUILD_TOOL=$1
if [[ -z "${BUILD_TOOL:-}" ]]; then
  echo "Missing build tool (require buck2 or cmake), exiting..."
  exit 1
else
  echo "Setup MacOS for ${BUILD_TOOL} ..."
fi

install_buck() {
  if ! command -v zstd &> /dev/null; then
    brew install zstd
  fi

  if ! command -v wget &> /dev/null; then
    brew install wget
  fi

  BUCK2_NOT_AVAILABLE=false
  if ! command -v buck2 &> /dev/null; then
    BUCK2_NOT_AVAILABLE=true
  else
    BUCK2_BINARY=$(which buck2)
    BUCK2_ARCH=$(file -b "${BUCK2_BINARY}")

    if [[ "${BUCK2_ARCH}" != "Mach-O 64-bit executable arm64" ]]; then
      echo "Reinstall buck2 because ${BUCK2_BINARY} is ${BUCK2_ARCH}, not 64-bit arm64"
      BUCK2_NOT_AVAILABLE=true
    fi
  fi

  if [[ "${BUCK2_NOT_AVAILABLE}" == true ]]; then
    pushd .ci/docker

    BUCK2=buck2-aarch64-apple-darwin.zst
    BUCK2_VERSION=$(cat ci_commit_pins/buck2.txt)

    wget -q "https://github.com/facebook/buck2/releases/download/${BUCK2_VERSION}/${BUCK2}"
    zstd -d "${BUCK2}" -o buck2

    chmod +x buck2
    mv buck2 /opt/homebrew/bin

    rm "${BUCK2}"
    popd
  fi
}

if [[ "${BUILD_TOOL}" == "buck2" ]]; then
  install_buck
fi
install_conda
install_pip_dependencies
install_executorch
build_executorch_runner "${BUILD_TOOL}"
