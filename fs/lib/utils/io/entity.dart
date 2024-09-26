// ignore_for_file: public_member_api_docs

library;

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
    return Directory(dir.path);
  }
}

/// get a child as a directory
Directory childDirectory(Directory dir, String sub) {
  return Directory(join(dir.path, sub));
}

///
/// convert to a file object if necessary
///
File asFile(FileSystemEntity file) {
  if (file is File) {
    return file;
  } else {
    return File(file.path);
  }
}

/// get a child as a file
File childFile(Directory dir, String sub) {
  return File(join(dir.path, sub));
}

///
/// convert to a link object if necessary
///
Link asLink(FileSystemEntity link) {
  if (link is Link) {
    return link;
  } else {
    return Link(link.path);
  }
}

/// get a child as a link
Link childLink(Directory dir, String sub) {
  return Link(join(dir.path, sub));
}

Future<bool> entityExists(FileSystemEntity entity) async {
  return (FileSystemEntity.typeSync(entity.path)) !=
      FileSystemEntityType.notFound;
}
