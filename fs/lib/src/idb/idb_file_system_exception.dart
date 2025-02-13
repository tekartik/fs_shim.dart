// ignore_for_file: public_member_api_docs

import 'package:fs_shim/fs.dart' as fs;

IdbError get _noSuchPathError => IdbError(2, 'No such file or directory');

IdbError get _notEmptyError => IdbError(39, 'Directory not empty');

IdbError get _alreadyExistsError => IdbError(17, 'File exists');

IdbError get _notADirectoryError => IdbError(20, 'Not a directory');

IdbError get _isADirectoryError => IdbError(21, 'Is a directory');

class IdbError implements fs.OSError {
  IdbError(this.errorCode, this.message);

  @override
  final int errorCode;
  @override
  final String message;

  @override
  String toString() {
    return '(OS Error: $message, errno = $errorCode)';
  }
}

IdbFileSystemException idbNotADirectoryException(String path, String msg) =>
    IdbFileSystemException(
      fs.FileSystemException.statusNotADirectory,
      path,
      msg,
      _notADirectoryError,
    );

IdbFileSystemException idbIsADirectoryException(String path, String msg) =>
    IdbFileSystemException(
      fs.FileSystemException.statusIsADirectory,
      path,
      msg,
      _isADirectoryError,
    );

IdbFileSystemException idbNotEmptyException(String path, String msg) =>
    IdbFileSystemException(
      fs.FileSystemException.statusNotEmpty,
      path,
      msg,
      _notEmptyError,
    );

IdbFileSystemException idbNotFoundException(String path, String msg) =>
    IdbFileSystemException(
      fs.FileSystemException.statusNotFound,
      path,
      msg,
      _noSuchPathError,
    );

IdbFileSystemException idbAlreadyExistsException(String path, String msg) =>
    IdbFileSystemException(
      fs.FileSystemException.statusAlreadyExists,
      path,
      msg,
      _alreadyExistsError,
    );

class IdbFileSystemException implements fs.FileSystemException {
  IdbFileSystemException(this.status, this.path, [this._message, this.osError]);

  @override
  final int status;

  final String? _message;
  @override
  final IdbError? osError;

  @override
  String get message => (_message ?? osError?.message)!;

  @override
  final String path;

  @override
  String toString() {
    return "${'[$status] '}FileSystemException: $message, path = '$path' $osError";
  }
}
