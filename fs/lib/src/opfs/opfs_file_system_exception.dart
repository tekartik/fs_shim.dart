// ignore_for_file: public_member_api_docs

import 'package:fs_shim/fs.dart' as fs;

OpfsError get _noSuchPathError => OpfsError(2, 'No such file or directory');

OpfsError get _notEmptyError => OpfsError(39, 'Directory not empty');

OpfsError get _alreadyExistsError => OpfsError(17, 'File exists');

OpfsError get _notADirectoryError => OpfsError(20, 'Not a directory');

OpfsError get _isADirectoryError => OpfsError(21, 'Is a directory');

/// OpfsError representation.
class OpfsError implements fs.OSError {
  OpfsError(this.errorCode, this.message);

  @override
  final int errorCode;
  @override
  final String message;

  @override
  String toString() {
    return '(OS Error: $message, errno = $errorCode)';
  }
}

OpfsFileSystemException opfsNotADirectoryException(String path, String msg) =>
    OpfsFileSystemException(
      fs.FileSystemException.statusNotADirectory,
      path,
      msg,
      _notADirectoryError,
    );

OpfsFileSystemException opfsIsADirectoryException(String path, String msg) =>
    OpfsFileSystemException(
      fs.FileSystemException.statusIsADirectory,
      path,
      msg,
      _isADirectoryError,
    );

OpfsFileSystemException opfsNotEmptyException(String path, String msg) =>
    OpfsFileSystemException(
      fs.FileSystemException.statusNotEmpty,
      path,
      msg,
      _notEmptyError,
    );

OpfsFileSystemException opfsNotFoundException(String path, String msg) =>
    OpfsFileSystemException(
      fs.FileSystemException.statusNotFound,
      path,
      msg,
      _noSuchPathError,
    );

OpfsFileSystemException opfsAlreadyExistsException(String path, String msg) =>
    OpfsFileSystemException(
      fs.FileSystemException.statusAlreadyExists,
      path,
      msg,
      _alreadyExistsError,
    );

/// OpfsFileSystemException representation.
class OpfsFileSystemException implements fs.FileSystemException {
  OpfsFileSystemException(
    this.status,
    this.path, [
    this._message,
    this.osError,
  ]);

  @override
  final int status;

  final String? _message;
  @override
  final OpfsError? osError;

  @override
  String get message => (_message ?? osError?.message)!;

  @override
  final String path;

  @override
  String toString() {
    return "[$status] FileSystemException: $message, path = '$path' $osError";
  }
}
