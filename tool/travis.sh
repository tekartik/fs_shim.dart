#!/usr/bin/env bash

set -xe

pushd fs
pub get
tool/travis.sh
popd
