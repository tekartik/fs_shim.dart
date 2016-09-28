#!/bin/bash

# Fast fail the script on failures.
set -e

dartanalyzer --fatal-warnings \
  lib/fs.dart \
  lib/fs_idb.dart \
  lib/fs_io.dart \
  lib/fs_memory.dart \

pub run test -p vm
# pub run test -p content-shell -j 1
# pub run test -p firefox -j 1 --reporter expanded