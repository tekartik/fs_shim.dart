library fs_shim.src.common.fs_path;

import 'package:path/path.dart';

String posixPath(String anyPath) {
  List<String> parts = windows.split(anyPath);
  return posix.joinAll(parts);
}
