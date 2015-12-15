library fs_shim.utils.entity;

import 'dart:async';
//import 'package:logging/logging.dart' as log;
import 'package:path/path.dart';
import '../fs.dart';
import '../src/common/import.dart';

///
/// convert to a directory object if necessary
///
Directory asDirectory(FileSystemEntity dir) {
  if (dir is Directory) {
    return dir;
  } else {
    return dir.fs.newDirectory(dir.path);
  }
}

/// get a child as a directory
Directory childDirectory(Directory dir, String sub) {
  return dir.fs.newDirectory(join(dir.path, sub));
}

///
/// convert to a file object if necessary
///
File asFile(FileSystemEntity file) {
  if (file is File) {
    return file;
  } else {
    return file.fs.newFile(file.path);
  }
}

/// get a child as a file
File childFile(Directory dir, String sub) {
  return dir.fs.newFile(join(dir.path, sub));
}

///
/// convert to a link object if necessary
///
Link asLink(FileSystemEntity link) {
  if (link is Link) {
    return link;
  } else {
    return link.fs.newLink(link.path);
  }
}

/// get a child as a link
Link childLink(Directory dir, String sub) {
  return dir.fs.newLink(join(dir.path, sub));
}

Future<bool> entityExists(FileSystemEntity entity) async {
  return (await entity.fs.type(entity.path)) != FileSystemEntityType.NOT_FOUND;
}
