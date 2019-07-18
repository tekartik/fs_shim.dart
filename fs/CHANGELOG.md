# Changelog

## 0.11.0+2

* Sdk 2.5 support

## 0.10.0

* deprecate ewFile, newDirectory, newLink, pathContext

## 0.9.0

* dart2 only

## 0.8.2

* add file, directory and link to replace newFile, newDirectory, newLink

## 0.7.3

* Add support `implicit-cast: false`

## 0.7.2

* Add `deleteFile`, `deleteDirectory`

## 0.7.1

Add io, deleteFile and deleteDirectory io helpers

## 0.6.6

Add copyDirectoryListFiles

## 0.6.5

Add copy io utils. Support including files

## 0.6.4

Add read_write io utils

## 0.6.3

Add io entity utils

## 0.6.0

Add copy utilities:
- copyDirectory
- copyFile
- createDirectory
- createFile
- deleteDirectory
- deleteFile

## 0.5.0

Add support for links in Directory.list

## 0.2.0

Classes

- File (create, openWrite, openRead, writeAsBytes, writeAsString, copy)
- Link (create, target)
- Directory (create, list)
- FileSystem (newDirectory, newFile, newLink, type, isFile, isDirectory, isLink)
- FileSystemEntity (path, exists, delete, rename, absolute, isAbsolute, state, parent)
- FileStat
- FileSystemEntityType,
- FileSystemException,

Static method (IO only)

- Directory.current
- FileSystemEntity.isFile
- FileSystemEntity.isDirectory
- FileSystemEntity.isLink

