import 'package:fs_shim/fs.dart';

FileSystem getIoFileSystem() =>
    throw UnsupportedError('ioFileSystem is not supported');
FileSystem getWebFileSystem() =>
    throw UnsupportedError('webFileSystem is not supported');
FileSystem getOpfsFileSystem() =>
    throw UnsupportedError('opfsFileSystem is not supported');

Future<FileSystem?> selectOpfsDirectory() {
  throw UnsupportedError('selectOpfsDirectory only supported on web');
}

Future<void> saveFile({required String name, required List<int> bytes}) {
  throw UnsupportedError('saveFile not supported on this platform');
}

Future<String?> pickDirectoryPath() {
  throw UnsupportedError('pickDirectoryPath not supported on this platform');
}

bool get isWebPlatform => false;
