// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE file.

/// File system implementation on top of the browser Origin Private File System
/// (OPFS), using raw web interop.
///
/// Safe to import on any platform, but [fileSystemOpfsWeb] is only available on
/// the web (relies on `navigator.storage.getDirectory()`).
///
/// See https://developer.mozilla.org/en-US/docs/Web/API/File_System_API/Origin_private_file_system
library;

import 'src/opfs/fs_opfs.dart';
import 'src/opfs/opfs_fs.dart';

export 'fs.dart';
export 'src/opfs/fs_opfs.dart' show FileSystemOpfsWebDirectoryHandle;
export 'src/opfs/opfs_fs.dart'
    show FileSystemOpfsWeb, FileSystemOpfsWebShowDirectoryPickerOptions;

/// The OPFS (Origin Private File System) file system.
///
/// There is a single OPFS per origin, this returns a shared instance.
///
/// Only available on the web (relies on `navigator.storage.getDirectory()`).
/// Links and random access are not supported.
FileSystemOpfsWeb get fileSystemOpfsWeb => fileSystemOpfsWebImpl;

/// File system rooted at an existing JS `FileSystemDirectoryHandle`.
///
/// [rootDirectoryHandle] must be a JS `FileSystemDirectoryHandle`, typically
/// obtained from [fileSystemOpfsWebShowDirectoryPicker] (Chromium-only) or
/// from a handle persisted in IndexedDB. Any interop binding works
/// (`package:web`, raw `dart:js_interop`, ...), the handle is used as-is.
///
/// ```dart
/// final handle = await fileSystemOpfsWebShowDirectoryPicker();
/// final fs = fileSystemOpfsWebWithRootHandle(handle);
/// ```
///
/// Write operations require the handle to have been granted `readwrite`
/// permission. Handles do not persist across page reloads unless saved by the
/// application (e.g. in IndexedDB) and permission requested again.
///
/// Only available on the web. Links and random access are not supported.
FileSystemOpfsWeb fileSystemOpfsWebWithRootHandle(
  FileSystemOpfsWebDirectoryHandle rootDirectoryHandle,
) => fileSystemOpfsWebWithRootHandleImpl(rootDirectoryHandle);

/// Prompts the user to select a directory using `window.showDirectoryPicker()`
/// (File System Access API) and returns the resulting
/// [FileSystemOpfsWebDirectoryHandle], suitable for
/// [fileSystemOpfsWebWithRootHandle].
///
/// See [FileSystemOpfsWebShowDirectoryPickerOptions] for the available
/// [options] (`id`, `mode`, `startIn`).
///
/// Chromium-only, must be called from a user gesture. Throws if the user
/// cancels the picker or if the browser does not support it.
///
/// Only available on the web.
Future<FileSystemOpfsWebDirectoryHandle> fileSystemOpfsWebShowDirectoryPicker([
  FileSystemOpfsWebShowDirectoryPickerOptions? options,
]) => fileSystemOpfsWebShowDirectoryPickerImpl(options);
