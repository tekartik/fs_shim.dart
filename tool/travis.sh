#!/bin/bash

# Fast fail the script on failures.
set -e

# Check dart2js warning: using dart2js example/demo_idb.dart --show-package-warnings -o /tmp/out.js

dartanalyzer --fatal-warnings \
  lib/fs.dart \
  lib/fs_idb.dart \
  lib/fs_io.dart \
  lib/fs_memory.dart \
  lib/utils/io/copy.dart \
  lib/utils/io/read_write.dart \
  lib/utils/io/entity.dart \

pub run test -p vm
pub run test -p chrome
# pub run test -p content-shell -j 1
# pub run test -p firefox -j 1 --reporter expanded

# test dartdevc support
pub build example/browser --web-compiler=dartdevc