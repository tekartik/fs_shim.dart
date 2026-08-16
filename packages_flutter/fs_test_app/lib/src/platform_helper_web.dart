import 'dart:js_interop';
import 'dart:typed_data';
import 'package:fs_shim/fs_browser.dart';
import 'package:fs_shim/fs_opfs_web.dart';
import 'package:web/web.dart' as web;

FileSystem getIoFileSystem() =>
    throw UnsupportedError('ioFileSystem is not supported on web');
FileSystem getWebFileSystem() => fileSystemWeb;
FileSystem getOpfsFileSystem() => fileSystemOpfsWeb;

Future<FileSystem?> selectOpfsDirectory() async {
  try {
    final dirHandle = await FileSystemOpfsWeb.showDirectoryPicker(
      FileSystemOpfsWebShowDirectoryPickerOptions(
        mode: FileSystemOpfsWebShowDirectoryPickerOptions.modeReadWrite,
      ),
    );
    return FileSystemOpfsWeb.withRootHandle(dirHandle);
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

bool get isWebPlatform => true;
