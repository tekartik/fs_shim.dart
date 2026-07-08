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
export 'src/opfs/fs_opfs.dart'
    show FileSystemOpfsWebDirectoryHandle, FileSystemOpfsWebFileHandle;
export 'src/opfs/opfs_fs.dart'
    show
        FileSystemOpfsWeb,
        FileSystemOpfsWebFilePickerAcceptType,
        FileSystemOpfsWebPickerOptions,
        FileSystemOpfsWebShowDirectoryPickerOptions,
        FileSystemOpfsWebShowOpenFilePickerOptions,
        FileSystemOpfsWebShowSaveFilePickerOptions;

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

/// File system whose root "directory" contains exactly [fileHandles], each at
/// `/<name>` (`name` being the JS handle name, deduplicated as `name (1)`,
/// `name (2)`, ... on collision).
///
/// Each element of [fileHandles] must be a JS `FileSystemFileHandle`,
/// typically obtained from [fileSystemOpfsWebShowOpenFilePicker] or
/// [fileSystemOpfsWebShowSaveFilePicker] (Chromium-only). Any interop binding
/// works (`package:web`, raw `dart:js_interop`, ...), the handles are used
/// as-is.
///
/// ```dart
/// final handles = await fileSystemOpfsWebShowOpenFilePicker(
///     FileSystemOpfsWebShowOpenFilePickerOptions(multiple: true));
/// final fs = fileSystemOpfsWebWithFileHandles(handles);
/// await for (final file in fs.directory('/').list()) {
///   print(await fs.file(file.path).readAsString());
/// }
/// ```
///
/// File handles give no access to their parent directory, so the structure is
/// fixed: the files can be read, written (permission permitting) and copied to
/// each other, but not created, deleted or renamed, and no directory can be
/// created. Handles from `showSaveFilePicker` are writable;
/// `showOpenFilePicker` handles are read-only unless granted `readwrite`
/// permission (see [fileSystemOpfsWebRequestWritePermission]).
///
/// Only available on the web. Links and random access are not supported.
FileSystemOpfsWeb fileSystemOpfsWebWithFileHandles(
  List<FileSystemOpfsWebFileHandle> fileHandles,
) => fileSystemOpfsWebWithFileHandlesImpl(fileHandles);

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

/// Prompts the user to select one or more files using
/// `window.showOpenFilePicker()` (File System Access API) and returns the
/// resulting [FileSystemOpfsWebFileHandle]s, suitable for
/// [fileSystemOpfsWebWithFileHandles].
///
/// See [FileSystemOpfsWebShowOpenFilePickerOptions] for the available
/// [options] (`id`, `startIn`, `multiple`, `excludeAcceptAllOption`, `types`).
///
/// The returned handles are read-only, writing requires requesting the
/// `readwrite` permission (see [fileSystemOpfsWebRequestWritePermission]).
///
/// Chromium-only, must be called from a user gesture. Throws if the user
/// cancels the picker or if the browser does not support it.
///
/// Only available on the web.
Future<List<FileSystemOpfsWebFileHandle>> fileSystemOpfsWebShowOpenFilePicker([
  FileSystemOpfsWebShowOpenFilePickerOptions? options,
]) => fileSystemOpfsWebShowOpenFilePickerImpl(options);

/// Prompts the user to select a file to save to using
/// `window.showSaveFilePicker()` (File System Access API) and returns the
/// resulting [FileSystemOpfsWebFileHandle], suitable for
/// [fileSystemOpfsWebWithFileHandles].
///
/// The file is created empty if it does not exist yet, and the returned handle
/// is granted `readwrite` permission.
///
/// See [FileSystemOpfsWebShowSaveFilePickerOptions] for the available
/// [options] (`id`, `startIn`, `suggestedName`, `excludeAcceptAllOption`,
/// `types`).
///
/// Chromium-only, must be called from a user gesture. Throws if the user
/// cancels the picker or if the browser does not support it.
///
/// Only available on the web.
Future<FileSystemOpfsWebFileHandle> fileSystemOpfsWebShowSaveFilePicker([
  FileSystemOpfsWebShowSaveFilePickerOptions? options,
]) => fileSystemOpfsWebShowSaveFilePickerImpl(options);

/// Requests the `readwrite` permission on a JS `FileSystemHandle` ([handle]
/// being a [FileSystemOpfsWebFileHandle] or a
/// [FileSystemOpfsWebDirectoryHandle]) and returns true if granted.
///
/// Needed before writing to a file handle obtained from
/// [fileSystemOpfsWebShowOpenFilePicker]. May prompt the user, in which case a
/// user gesture is required.
///
/// Chromium-only. Only available on the web.
Future<bool> fileSystemOpfsWebRequestWritePermission(Object handle) =>
    fileSystemOpfsWebRequestWritePermissionImpl(handle);
