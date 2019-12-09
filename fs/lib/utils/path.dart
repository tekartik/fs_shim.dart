library fs_shim.utils.path;

import 'package:fs_shim/src/common/import.dart';

String posixPath(String anyPath) {
  final parts = splitParts(anyPath);
  return posix.joinAll(parts);
}

String contextPath(String anyPath) {
  final parts = splitParts(anyPath);
  return joinAll(parts);
}

bool get contextIsWindows => context.style == windows.style;
