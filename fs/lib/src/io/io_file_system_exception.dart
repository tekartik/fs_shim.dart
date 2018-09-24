library fs_shim.src.io.io_file_system_exception;

import '../../fs.dart' as fs;
export '../../fs.dart' show FileSystemEntityType;
import 'dart:io' as io;

class OSErrorImpl implements fs.OSError {
  io.OSError ioOSError;
  OSErrorImpl.io(this.ioOSError);
  @override
  int get errorCode => ioOSError.errorCode;
  @override
  String get message => ioOSError.message;

  @override
  String toString() => ioOSError.toString();
}

int _statusFromException(io.FileSystemException ioFse) {
  // linux error code is 2
  int status;
  if (ioFse != null && ioFse.osError != null) {
    int errorCode = ioFse.osError.errorCode;

    if (io.Platform.isWindows) {
      // https://msdn.microsoft.com/en-us/library/windows/desktop/ms681387(v=vs.85).aspx
      switch (errorCode) {
        case 2: // ERROR_FILE_NOT_FOUND
        case 3: // ERROR_PATH_NOT_FOUND
          status = fs.FileSystemException.statusNotFound;
          break;
        case 5: // ERROR_ACCESS_DENIED
          status = fs.FileSystemException.statusAccessError;
          break;
        case 145: // ERROR_DIR_NOT_EMPTY
          status =
              fs.FileSystemException.statusNotEmpty; // for recursive delete
          break;
        case 183: // ERROR_ALREADY_EXISTS
          status = fs.FileSystemException.statusAlreadyExists;
          break;
        case 4390: // ERROR_NOT_A_REPARSE_POINT (links)
          status = fs.FileSystemException.statusInvalidArgument;
          break;
      }
    }
    if (io.Platform.isMacOS) {
      // http://www.ioplex.com/~miallen/errcmp.html
      switch (errorCode) {
        case 2: // No such file or directory
          status = fs.FileSystemException.statusNotFound;
          break;
        case 17:
          status = fs.FileSystemException.statusAlreadyExists;
          break;
        case 20: // Not a directory
          status = fs.FileSystemException.statusNotADirectory;
          break;
        case 21:
          status = fs.FileSystemException.statusIsADirectory;
          break;
        case 22:
          status = fs.FileSystemException.statusInvalidArgument;
          break;
        case 66: // Directory not empty
          status =
              fs.FileSystemException.statusNotEmpty; // for recursive delete
          break;
      }
    } else {
      // tested mainly on linux
      // http://www-numi.fnal.gov/offline_software/srt_public_context/WebDocs/Errors/unix_system_errors.html
      switch (errorCode) {
        case 2:
          status = fs.FileSystemException.statusNotFound;
          break;
        case 17:
          status = fs.FileSystemException.statusAlreadyExists;
          break;
        case 20:
          status = fs.FileSystemException.statusNotADirectory;
          break;
        case 21:
          status = fs.FileSystemException.statusIsADirectory;
          break;
        case 22:
          status = fs.FileSystemException.statusInvalidArgument;
          break;
        case 39:
          status =
              fs.FileSystemException.statusNotEmpty; // for recursive delete
          break;
      }
    }
  }
  return status;
}

class FileSystemExceptionImpl implements fs.FileSystemException {
  io.FileSystemException ioFileSystemException;

  FileSystemExceptionImpl.io(io.FileSystemException ioFse)
      : ioFileSystemException = ioFse,
        osError = OSErrorImpl.io(ioFse.osError),
        status = _statusFromException(ioFse);

  @override
  final int status;

  @override
  final OSErrorImpl osError;

  @override
  String get message => ioFileSystemException.message;

  @override
  String get path => ioFileSystemException.path;

  @override
  String toString() =>
      "${status == null ? '' : '[${status}] '}${ioFileSystemException.toString()}";
}
