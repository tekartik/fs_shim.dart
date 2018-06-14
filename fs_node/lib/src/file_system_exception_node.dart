library fs_shim.src.io.io_file_system_exception;

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs.dart';
import 'import_common_node.dart' as io;

// OSError Wrap/unwrap
OSErrorNode wrapIoOSError(io.OSError ioOSError) =>
    ioOSError != null ? new OSErrorNode.io(ioOSError) : null;
io.OSError unwrapIoOSError(OSError osError) =>
    osError != null ? (osError as OSErrorNode).ioOSError : null;

class OSErrorNode implements fs.OSError {
  io.OSError ioOSError;
  OSErrorNode.io(this.ioOSError);
  int get errorCode => ioOSError.errorCode;
  String get message => ioOSError.message;

  @override
  String toString() => ioOSError.toString();
}

// FileSystemException Wrap/unwrap
FileSystemException wrapIoFileSystemException(
        io.FileSystemException ioFileSystemException) =>
    new FileSystemExceptionNode.io(ioFileSystemException);
io.FileSystemException unwrapIoFileSystemException(
        FileSystemException fileSystemException) =>
    (fileSystemException as FileSystemExceptionNode).ioFileSystemException;

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

class FileSystemExceptionNode implements fs.FileSystemException {
  io.FileSystemException ioFileSystemException;

  FileSystemExceptionNode.io(io.FileSystemException ioFse)
      : ioFileSystemException = ioFse,
        osError = new OSErrorNode.io(ioFse.osError),
        status = _statusFromException(ioFse);

  @override
  final int status;

  @override
  final OSErrorNode osError;

  @override
  String get message => ioFileSystemException.message;

  @override
  String get path => ioFileSystemException.path;

  @override
  String toString() =>
      "${status == null ? '' : '[${status}] '}${ioFileSystemException.toString()}";
}
