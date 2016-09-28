library fs_shim.utils.entity;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
//import 'package:logging/logging.dart' as log;

///
/// convert to a directory object if necessary
///
Directory asDirectory(FileSystemEntity dir) {
  if (dir is Directory) {
    return dir;
  } else {
    return new Directory(dir.path);
  }
}

/// get a child as a directory
Directory childDirectory(Directory dir, String sub) {
  return new Directory(join(dir.path, sub));
}

///
/// convert to a file object if necessary
///
File asFile(FileSystemEntity file) {
  if (file is File) {
    return file;
  } else {
    return new File(file.path);
  }
}

/// get a child as a file
File childFile(Directory dir, String sub) {
  return new File(join(dir.path, sub));
}

///
/// convert to a link object if necessary
///
Link asLink(FileSystemEntity link) {
  if (link is Link) {
    return link;
  } else {
    return new Link(link.path);
  }
}

/// get a child as a link
Link childLink(Directory dir, String sub) {
  return new Link(join(dir.path, sub));
}

Future<bool> entityExists(FileSystemEntity entity) async {
  return (await FileSystemEntity.type(entity.path)) !=
      FileSystemEntityType.NOT_FOUND;
}
