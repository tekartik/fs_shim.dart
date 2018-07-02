#!/usr/bin/env bash

# Fast fail the script on failures.
set -xe

# Check dart2js warning: using dart2js example/demo_idb.dart --show-package-warnings -o /tmp/out.js

dartanalyzer --fatal-warnings .

# failing for now 2018-06-30 pub run test -p vm,chrome
pub run test -p vm
pub run build_runner test -- -p vm,chrome
