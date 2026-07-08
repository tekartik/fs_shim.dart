import 'dart:js_interop';
import 'dart:typed_data';
import 'package:fs_shim/fs_browser.dart';
import 'package:fs_shim/fs_opfs_web.dart';
import 'package:web/web.dart' as web;

FileSystem getIoFileSystem() =>
    throw UnsupportedError('ioFileSystem is not supported on web');
FileSystem getWebFileSystem() => fileSystemWeb;
FileSystem getOpfsFileSystem() => fileSystemOpfsWeb;

@JS('window.showDirectoryPicker')
external JSPromise<JSObject> _showDirectoryPicker();

Future<FileSystem?> selectOpfsDirectory() async {
  try {
    final dirHandle = await _showDirectoryPicker().toDart;
    return fileSystemOpfsWebWithRootHandle(dirHandle);
  } catch (e) {
    return null;
  }
}

Future<void> saveFile({required String name, required List<int> bytes}) async {
  final uint8List = Uint8List.fromList(bytes);
  final blob = web.Blob([uint8List.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = name;
  anchor.click();
  web.URL.revokeObjectURL(url);
}

Future<String?> pickDirectoryPath() async {
  return null;
}

Future<Uint8List> readBytesFromPath(String path) async {
  throw UnsupportedError('readBytesFromPath not supported on web');
}

bool get isWebPlatform => true;
