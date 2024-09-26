library;

import 'package:path/path.dart' as p;

///
/// Get the parts from any style (linux/windows)
///
///     C:\windows
///     /opt/apps
///
/// First part is context dependent so this should onl be used in a file
/// system io context on windows.
@Deprecated('No longer exported')
List<String> splitParts(String anyPath) => _parts(anyPath);

List<String> _parts(String anyPath) {
  final parts = p.windows.split(anyPath);
  return parts;
}
