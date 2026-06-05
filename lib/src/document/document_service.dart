// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:archive/archive_io.dart';

/// DocumentService serves as an abstraction of the interaction with the system. It can
/// be injected to other functions to e.g. write to the file system, while
/// a different class inheriting from this can be used for the unit tests.
///
/// This also allows us to replace the actual source of the documents.
class DocumentService {
  DocumentService();

  /// Synchronously checks if a file exists in [path]
  bool fileExistsSync(String path) {
    return File(path).existsSync();
  }

  /// Synchronously reads the entire file in [path]
  String readFileSync(String path) {
    return File(path).readAsStringSync();
  }

  /// Synchronously writes the entire [text] to a file called [path]
  void writeFileSync(String path, String text) {
    File(path).writeAsStringSync(text);
  }

  /// Asynchronously checks if a file exists in [path]
  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  /// Asynchronously reads the entire file in [path]
  Future<String> read(String path) async {
    return File(path).readAsString();
  }

  /// Asynchronously reads the entire file in [path] as bytes
  Future<Uint8List> readAsBytes(String path) async {
    return File(path).readAsBytes();
  }

  /// Asynchronously reads the zip archive in [path]
  Future<Map<String, Uint8List>> loadZipArchive(String path) async {
    final bytes = await readAsBytes(path);
    final archive = ZipDecoder().decodeBytes(bytes);
    Map<String, Uint8List> contents = {};
    for (final entry in archive) {
      if (entry.isFile) {
        final fileBytes = entry.readBytes();
        if (fileBytes != null) {
          contents[entry.name] = fileBytes;
        }
      }
    }
    return contents;
  }

  /// Asynchronously writes the [files] as zip archive in [path]
  Future<void> saveAsZipArchive(
      String path, Map<String, Uint8List> files) async {
    final fileList = <ArchiveFile>[];
    for (final file in files.entries) {
      fileList.add(ArchiveFile.typedData(file.key, file.value));
    }
    await _saveZipArchive(path, fileList);
  }

  /// Asynchronously writes the [files] as zip archive in [path]
  Future<void> _saveZipArchive(String path, List<ArchiveFile> files) async {
    var encoder = ZipFileEncoder();
    encoder.create(path);
    for (final file in files) {
      encoder.addArchiveFile(file);
    }
    await encoder.close();
  }

  /// Asynchronously writes the entire [text] to a file called [path]
  Future<void> write(String path, String text) async {
    await File(path).writeAsString(text, flush: true);
    return;
  }
}
