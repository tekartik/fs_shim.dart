library fs_shim.utils.part;

import 'package:path/path.dart' as _path;

///
/// Get the parts from any style (linux/windows)
///
///     C:\windows
///     /opt/apps
///
/// First part is context dependent so this should onl be used in a file
/// system io context on windows.
@deprecated
List<String> splitParts(String anyPath) => _parts(anyPath);

List<String> _parts(String anyPath) {
  final parts = _path.windows.split(anyPath);
  return parts;
}
