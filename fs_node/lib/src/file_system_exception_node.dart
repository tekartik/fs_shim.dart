library fs_shim.src.io.io_file_system_exception;

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs.dart';
import 'package:tekartik_fs_node/src/utils.dart';
import 'import_common_node.dart' as io;

// OSError Wrap/unwrap
OSErrorNode wrapIoOSError(io.OSError ioOSError) =>
    ioOSError != null ? OSErrorNode.io(ioOSError) : null;
io.OSError unwrapIoOSError(OSError osError) =>
    osError != null ? (osError as OSErrorNode)?.ioOSError : null;

class OSErrorNode implements fs.OSError {
  io.OSError ioOSError;
  OSErrorNode.io(this.ioOSError);
  @override
  int get errorCode => ioOSError.errorCode;
  @override
  String get message => ioOSError.message;

  @override
  String toString() => ioOSError?.toString() ?? 'OSErrorNode';
}

// FileSystemException Wrap/unwrap
FileSystemException wrapIoFileSystemException(
        io.FileSystemException ioFileSystemException) =>
    ioFileSystemException == null
        ? null
        : FileSystemExceptionNode.io(ioFileSystemException);
io.FileSystemException unwrapIoFileSystemException(
        FileSystemException fileSystemException) =>
    (fileSystemException as FileSystemExceptionNode)?.ioFileSystemException;

int _statusFromException(io.FileSystemException ioFse) {
  // linux error code is 2
  int status;
  if (ioFse != null && ioFse.osError != null) {
    final errorCode = ioFse.osError.errorCode;

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

  FileSystemExceptionNode({this.status, String message})
      : _message = message,
        ioFileSystemException = null,
        osError = null;

  FileSystemExceptionNode.fromString(String e)
      : _message = e,
        status = statusFromMessage(e),
        ioFileSystemException = null,
        osError = osErrorFromMessage(e);

  FileSystemExceptionNode.io(this.ioFileSystemException)
      : osError = OSErrorNode.io(ioFileSystemException.osError),
        status = _statusFromException(ioFileSystemException),
        _message = ioFileSystemException.message;

  @override
  final int status;

  @override
  final OSErrorNode osError;

  final String _message;

  @override
  String get message => _message;

  @override
  String get path => ioFileSystemException.path;

  @override
  String toString() => "${status == null ? '' : '[$status] '}$message";
}

OSErrorNode osErrorFromMessage(String message) {
  return wrapIoOSError(io.OSError(message));
}
