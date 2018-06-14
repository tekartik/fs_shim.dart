#!/usr/bin/env bash

set -xe

pushd fs_test
pub get
tool/travis.sh
popd
