// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:io';

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

  /// Asynchronously writes the entire [text] to a file called [path]
  Future<void> write(String path, String text) async {
    await File(path).writeAsString(text, flush: true);
    return;
  }
}
