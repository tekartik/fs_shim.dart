#!/usr/bin/env bash

set -xe

pushd fs
pub get
tool/travis.sh
popd

pushd fs_test
pub get
tool/travis.sh
popd

pushd fs_node
pub get
tool/travis.sh
popd