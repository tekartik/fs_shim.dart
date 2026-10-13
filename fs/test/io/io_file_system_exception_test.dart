@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:fs_shim/fs_io.dart';
import 'package:test/test.dart';

void main() {
  group('io_file_system_exception', () {
    test('status', () {
      FileSystemException wrap(int errorCode) => wrapIoFileSystemException(
        io.FileSystemException('msg', 'path', io.OSError('os', errorCode)),
      );
      expect(wrap(2).status, FileSystemException.statusNotFound);
      expect(wrap(2).osError!.errorCode, 2);
      if (io.Platform.isLinux || io.Platform.isMacOS) {
        expect(wrap(13).status, FileSystemException.statusAccessError);
        expect(wrap(17).status, FileSystemException.statusAlreadyExists);
        expect(wrap(20).status, FileSystemException.statusNotADirectory);
        expect(wrap(21).status, FileSystemException.statusIsADirectory);
        expect(wrap(22).status, FileSystemException.statusInvalidArgument);
      }
      if (io.Platform.isWindows) {
        // Windows codes are not linux ones (17 is ERROR_NOT_SAME_DEVICE).
        expect(wrap(17).status, isNull);
        expect(wrap(183).status, FileSystemException.statusAlreadyExists);
      }
    });

    test('no os error', () {
      // Such as a bad utf8 encoding.
      var exception = wrapIoFileSystemException(
        const io.FileSystemException('msg', 'path'),
      );
      expect(exception.osError, isNull);
      expect(exception.status, isNull);
      expect(wrapIoOSError(null), isNull);
      expect(wrapIoOSError(const io.OSError('os', 2))!.errorCode, 2);
    });
  });
}
