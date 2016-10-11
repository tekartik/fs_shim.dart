# Changelog

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

