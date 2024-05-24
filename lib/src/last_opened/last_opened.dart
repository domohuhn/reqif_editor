// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

class FileData {
  String title;
  String path;
  DateTime lastUsed;
  FileData(this.title, this.path, this.lastUsed);
}

/// A sorted list of the last used files.
class LastOpenedFiles {
  static const int maxFilesToKeep = 16;

  final List<FileData> _files;
  LastOpenedFiles(this._files);

  Iterable<FileData> get files => _files;

  /// Adds or updates the file, sorts the list and removes excess entries.
  void addFile(String title, String path) {
    var idx = _files.indexWhere((element) => element.path == path);
    if (idx < 0) {
      _files.add(FileData(title, path, DateTime.now()));
    } else {
      _files[idx].title = title;
      _files[idx].lastUsed = DateTime.now();
    }
    _files.sort((a, b) => -a.lastUsed.compareTo(b.lastUsed));
    if (_files.length > maxFilesToKeep) {
      _files.removeRange(maxFilesToKeep, _files.length);
    }
  }
}
