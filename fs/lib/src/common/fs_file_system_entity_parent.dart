import 'package:fs_shim/fs.dart';

/// Entity or FileSystem
abstract class FileSystemEntityParent {
  /// Directory from an optional path, null meaning itself for Directory,
  /// currentDirectory for FileSystem
  Directory directoryWith({String? path});

  /// Child directory
  Directory directory(String path);

  /// Child file
  File file(String path);

  /// Child link
  Link link(String path);

  /// Child path
  String childPath(String path);
}
