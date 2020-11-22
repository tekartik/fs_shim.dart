library fs_shim.utils.entity;

import 'dart:async';

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/src/common/import.dart';

///
/// convert to a directory object if necessary
///
Directory asDirectory(FileSystemEntity? dir) {
  if (dir is Directory) {
    return dir;
  } else {
    return dir!.fs.directory(dir.path);
  }
}

/// get a child as a directory
Directory childDirectory(Directory dir, String sub) {
  return dir.fs.directory(dir.fs.path.join(dir.path, sub));
}

///
/// convert to a file object if necessary
///
File asFile(FileSystemEntity file) {
  if (file is File) {
    return file;
  } else {
    return file.fs.file(file.path);
  }
}

/// get a child as a file
File childFile(Directory dir, String sub) {
  return dir.fs.file(dir.fs.path.join(dir.path, sub));
}

///
/// convert to a link object if necessary
///
Link asLink(FileSystemEntity link) {
  if (link is Link) {
    return link;
  } else {
    return link.fs.link(link.path);
  }
}

/// get a child as a link
Link childLink(Directory dir, String sub) {
  return dir.fs.link(dir.fs.path.join(dir.path, sub));
}

Future<bool> entityExists(FileSystemEntity entity) async {
  return (await entity.fs.type(entity.path)) != FileSystemEntityType.notFound;
}
