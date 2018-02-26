#!/bin/bash

# Fast fail the script on failures.
set -e

# Check dart2js warning: using dart2js example/demo_idb.dart --show-package-warnings -o /tmp/out.js

dartanalyzer --fatal-warnings .

pub run test -p vm
pub run test -p chrome
# pub run test -p content-shell -j 1
# pub run test -p firefox -j 1 --reporter expanded

# test dartdevc support
pub build example/browser --web-compiler=dartdevc