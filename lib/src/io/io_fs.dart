library fs_shim.src.io.io_fs;

import 'dart:async';
import '../../fs_io.dart';
import 'dart:io' as io;

ioWrapError(e) {
  if (e is io.FileSystemException) {
    return new FileSystemException(e);
  }
  return e;
}

Future ioWrap(Future future) {
  return future.catchError((e) {
    throw ioWrapError(e);
  }, test: (e) => (e is io.FileSystemException));
}