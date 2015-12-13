library fs_shim.src.idb.idb_file_system_exception;

import '../../fs.dart' as fs;

IdbError get _noSuchPathError => new IdbError(2, "No such file or directory");
IdbError get _notEmptyError => new IdbError(39, "Directory not empty");
IdbError get _alreadyExistsError => new IdbError(17, "File exists");
IdbError get _notADirectoryError => new IdbError(20, "Not a directory");
IdbError get _isADirectoryError => new IdbError(21, "Is a directory");

class IdbError implements fs.OSError {
  IdbError(this.errorCode, this.message);
  final int errorCode;
  final String message;

  @override
  String toString() {
    return "(OS Error: ${message}, errno = ${errorCode})";
  }
}

idbNotADirectoryException(String path, String msg) =>
    new IdbFileSystemException(fs.FileSystemException.statusNotADirectory, path,
        msg, _notADirectoryError);

idbIsADirectoryException(String path, String msg) => new IdbFileSystemException(
    fs.FileSystemException.statusIsADirectory, path, msg, _isADirectoryError);

idbNotEmptyException(String path, String msg) => new IdbFileSystemException(
    fs.FileSystemException.statusNotEmpty, path, msg, _notEmptyError);

idbNotFoundException(String path, String msg) => new IdbFileSystemException(
    fs.FileSystemException.statusNotFound, path, msg, _noSuchPathError);

idbAlreadyExistsException(String path, String msg) =>
    new IdbFileSystemException(fs.FileSystemException.statusAlreadyExists, path,
        msg, _alreadyExistsError);

class IdbFileSystemException implements fs.FileSystemException {
  IdbFileSystemException(this.status, this.path, [this._message, this.osError]);

  @override
  final int status;

  String _message;
  @override
  final IdbError osError;

  @override
  String get message =>
      _message == null ? (osError == null ? null : osError.message) : _message;

  @override
  final String path;

  @override
  String toString() {
    return "${status == null ? '' : '[${status}] '}FileSystemException: ${message}, path = '${path}' ${osError}";
  }
}
