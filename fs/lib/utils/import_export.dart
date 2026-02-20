import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:fs_shim/utils/copy.dart';
import 'package:idb_shim/utils/idb_import_export.dart';

///
/// Copy a database export to another
///
/// return the opened database
///
Future<void> fsIdbImport(FileSystem fs, Object data) async {
  var newIdbFactory = newIdbFactoryMemory();
  var dbName = 'fs';
  // Import and close
  var idbDatabase = await idbImportDatabase(data, newIdbFactory, dbName);
  idbDatabase.close();
  // Reopen as a file system
  var importFs = newFileSystemIdb(newIdbFactory, dbName);
  if (await importFs.currentDirectory.exists()) {
    await copyDirectory(
      importFs.currentDirectory,
      fs.currentDirectory,
      options: CopyOptions(recursive: true),
    );
  }
}

///
/// export a database in a idb export format
///
/// Use sandbox to limit what to export
///
Future<List<Object>> fsIdbExportLines(FileSystem fs) async {
  // if already a sembast database use it
  // if (false) {
  if (fs is FileSystemIdb) {
    var fsIdb = fs;
    var idbDatabase = await fsIdb.readyDatabase;
    return idbExportDatabaseLines(idbDatabase);
  } else {
    var newFs = newFileSystemMemory();
    assert(newFs is FileSystemIdb);
    if (await fs.currentDirectory.exists()) {
      await copyDirectory(
        fs.currentDirectory,
        newFs.currentDirectory,
        options: CopyOptions(recursive: true, verbose: false),
      );
    }
    return await fsIdbExportLines(newFs);
  }
}
