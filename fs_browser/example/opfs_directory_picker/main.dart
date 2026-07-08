import 'dart:js_interop';

import 'package:fs_shim/fs_opfs_web.dart';
import 'package:web/web.dart' as web;

/// `window.showDirectoryPicker()` (File System Access API), not exposed by
/// `package:web`. Chromium-only, must be called from a user gesture.
@JS('window.showDirectoryPicker')
external JSPromise<JSObject> _showDirectoryPicker();

Future<void> main() async {
  final button = web.document.querySelector('#pick') as web.HTMLButtonElement;
  final output = web.document.querySelector('#output') as web.HTMLPreElement;

  void write(Object? msg) {
    output.textContent = '${output.textContent}$msg\n';
  }

  button.onClick.listen((_) async {
    output.textContent = '';
    final JSObject dirHandle;
    try {
      dirHandle = await _showDirectoryPicker().toDart;
    } catch (e) {
      // Cancelled by the user (or unsupported browser).
      write('No directory selected ($e)');
      return;
    }

    final fs = fileSystemOpfsWebWithRootHandle(dirHandle);
    write('Content of the selected directory:');
    final entities = await fs.directory('/').list().toList();
    entities.sort((a, b) => a.path.compareTo(b.path));
    if (entities.isEmpty) {
      write('(empty)');
    }
    for (final entity in entities) {
      write('${entity.path} ${await entity.stat()}');
    }
  });
}
