library fs_shim.utils.part;

import 'package:path/path.dart' as _path;

///
/// Get the parts from any style (linux/windows)
///
///     C:\windows
///     /opt/apps
///
List<String> splitParts(String anyPath) => _parts(anyPath);

List<String> _parts(String anyPath) {
  List<String> parts = _path.windows.split(anyPath);
  return parts;
}
