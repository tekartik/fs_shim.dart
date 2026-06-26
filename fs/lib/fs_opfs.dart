// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE file.

/// File system implementation on top of the browser Origin Private File System
/// (OPFS), using raw web interop.
///
/// See https://developer.mozilla.org/en-US/docs/Web/API/File_System_API/Origin_private_file_system
library;

import 'src/opfs/opfs_file_system.dart';

export 'fs.dart';
export 'src/opfs/opfs_file_system.dart' show FileSystemOpfs;

FileSystemOpfs? _fileSystemOpfs;

/// The OPFS (Origin Private File System) file system.
///
/// There is a single OPFS per origin, this returns a shared instance.
///
/// Only available on the web (relies on `navigator.storage.getDirectory()`).
/// Links and random access are not supported.
FileSystemOpfs get fileSystemOpfs => _fileSystemOpfs ??= FileSystemOpfs();
