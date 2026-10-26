import 'dart:js_interop';

import 'package:fs_shim/fs_opfs_web.dart';
import 'package:idb_shim/sdb.dart';
import 'package:web/web.dart' as web;

/// Saved handles, keyed by kind ([_kindFile] or [_kindDirectory]).
final _handleStore = SdbStoreRef<String, SdbModel>('handle');

const _kindFile = 'file';
const _kindDirectory = 'directory';

/// OPFS directory of the demo file (see the 'Use an OPFS file' button).
const _opfsDirName = 'opfs_handle_sdb';
const _opfsFileName = 'demo.txt';

Future<void> main() async {
  final output = web.document.querySelector('#output') as web.HTMLPreElement;

  void write(Object? msg) {
    output.textContent = '${output.textContent}$msg\n';
  }

  void onClick(String id, Future<void> Function() action) {
    final button = web.document.querySelector('#$id') as web.HTMLButtonElement;
    button.onClick.listen((_) async {
      output.textContent = '';
      try {
        await action();
      } catch (e) {
        // Cancelled picker, unsupported browser, file moved or deleted...
        write('Error: $e');
      }
    });
  }

  final db = await sdbFactoryWeb.openDatabase(
    'opfs_handle_sdb.db',
    options: SdbOpenDatabaseOptions(
      version: 1,
      schema: SdbDatabaseSchema(stores: [_handleStore.schema()]),
    ),
  );

  Future<void> save(
    String kind,
    FileSystemOpfsWebFileSystemEntityHandle handle,
  ) async {
    // The JS handle is stored as is (structured clone), next to other data.
    await _handleStore.record(kind).put(db, {
      'name': handle.name,
      'savedAt': SdbTimestamp.now(),
      'handle': SdbNativeValue(handle.jsObject),
    });
    write('Saved $kind ${handle.name}');
  }

  Future<FileSystemOpfsWebFileSystemEntityHandle?> load(String kind) async {
    final model = await _handleStore.record(kind).getValue(db);
    if (model == null) {
      return null;
    }
    final jsObject = (model['handle'] as SdbNativeValue).jsObject;
    return kind == _kindFile
        ? FileSystemOpfsWebFileHandle.fromJsObject(jsObject)
        : FileSystemOpfsWebDirectoryHandle.fromJsObject(jsObject);
  }

  Future<void> open(FileSystemOpfsWebFileSystemEntityHandle handle) async {
    if (handle is FileSystemOpfsWebFileHandle) {
      final fs = FileSystemOpfsWeb.withFileHandles([handle]);
      final file = fs.file('/${handle.name}');
      write('${file.path} ${await file.stat()}');
      write(await file.readAsString());
    } else if (handle is FileSystemOpfsWebDirectoryHandle) {
      final fs = FileSystemOpfsWeb.withRootHandle(handle);
      final entities = await fs.directory('/').list().toList();
      entities.sort((a, b) => a.path.compareTo(b.path));
      write('Content of ${handle.name}:');
      if (entities.isEmpty) {
        write('(empty)');
      }
      for (final entity in entities) {
        write('${entity.path} ${await entity.stat()}');
      }
    }
  }

  Future<void> restore(String kind) async {
    final handle = await load(kind);
    if (handle == null) {
      write('No saved $kind');
      return;
    }
    // Permissions do not survive a reload by default (Chromium), asking
    // again requires a user gesture (this button click).
    var state = await FileSystemOpfsWeb.queryPermission(handle);
    write('${handle.name} permission: $state');
    if (state != FileSystemOpfsWeb.permissionGranted) {
      state = await FileSystemOpfsWeb.requestPermission(handle);
      write('${handle.name} requested permission: $state');
      if (state != FileSystemOpfsWeb.permissionGranted) {
        return;
      }
    }
    await open(handle);
  }

  Future<void> showSaved() async {
    for (final kind in [_kindFile, _kindDirectory]) {
      final model = await _handleStore.record(kind).getValue(db);
      if (model == null) {
        write('No saved $kind');
        continue;
      }
      final state = await FileSystemOpfsWeb.queryPermission(
        (await load(kind))!,
      );
      write(
        'Saved $kind: ${model['name']} at ${model['savedAt']} '
        '(permission: $state)',
      );
    }
  }

  onClick('pick-file', () async {
    final handles = await FileSystemOpfsWeb.showOpenFilePicker();
    await save(_kindFile, handles.first);
    await open(handles.first);
  });
  onClick('pick-directory', () async {
    final handle = await FileSystemOpfsWeb.showDirectoryPicker();
    await save(_kindDirectory, handle);
    await open(handle);
  });
  onClick('opfs-file', () async {
    // Write a file in the OPFS through fs_shim.
    final file = fileSystemOpfsWeb.file('/$_opfsDirName/$_opfsFileName');
    await file.create(recursive: true);
    await file.writeAsString('Written by fs_shim at ${DateTime.now()}\n');
    // Its handle, from another interop binding (package:web).
    final root = await web.window.navigator.storage.getDirectory().toDart;
    final dir = await root.getDirectoryHandle(_opfsDirName).toDart;
    final jsHandle = await dir.getFileHandle(_opfsFileName).toDart;
    final handle = FileSystemOpfsWebFileHandle.fromJsObject(jsHandle);
    await save(_kindFile, handle);
    await open(handle);
  });
  onClick('restore-file', () => restore(_kindFile));
  onClick('restore-directory', () => restore(_kindDirectory));
  onClick('forget', () async {
    await _handleStore.record(_kindFile).delete(db);
    await _handleStore.record(_kindDirectory).delete(db);
    write('Forgotten');
  });

  await showSaved();
}
