// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

class FileData {
  String title;
  String path;
  String columnOrder;
  String columnVisibility;
  String mergeOptions;
  DateTime lastUsed;
  FileData(this.title, this.path, this.lastUsed, this.columnOrder,
      this.columnVisibility, this.mergeOptions);
}

/// A sorted list of the last used files.
class LastOpenedFiles {
  static const int maxFilesToKeep = 16;

  final List<FileData> _files;
  LastOpenedFiles(this._files);

  Iterable<FileData> get files => _files;

  /// Adds or updates the file, sorts the list and removes excess entries.
  void addFile(String title, String path) {
    final idx = _files.indexWhere((element) => element.path == path);
    if (idx < 0) {
      _files.add(FileData(title, path, DateTime.now(), '{}', '{}', '{}'));
    } else {
      _files[idx].title = title;
      _files[idx].lastUsed = DateTime.now();
    }
    _files.sort((a, b) => -a.lastUsed.compareTo(b.lastUsed));
    if (_files.length > maxFilesToKeep) {
      _files.removeRange(maxFilesToKeep, _files.length);
    }
  }

  /// Updates the order of columns to display.
  ///
  /// Returns true if data was updated
  bool updateColumnOrder(String path, String order) {
    final idx = _files.indexWhere((element) => element.path == path);
    final inRange = idx >= 0 && idx < _files.length;
    var updated = false;
    if (inRange) {
      if (_files[idx].columnOrder != order) {
        _files[idx].columnOrder = order;
        updated = true;
      }
    }
    return updated;
  }

  /// Updates the visibility of columns to display.
  ///
  /// Returns true if data was updated
  bool updateColumnVisibility(String path, String visibility) {
    final idx = _files.indexWhere((element) => element.path == path);
    final inRange = idx >= 0 && idx < _files.length;
    var updated = false;
    if (inRange) {
      if (_files[idx].columnVisibility != visibility) {
        _files[idx].columnVisibility = visibility;
        updated = true;
      }
    }
    return updated;
  }

  /// Updates the merge options of columns.
  ///
  /// Returns true if data was updated
  bool updateColumnMergeOptions(String path, String options) {
    final idx = _files.indexWhere((element) => element.path == path);
    final inRange = idx >= 0 && idx < _files.length;
    var updated = false;
    if (inRange) {
      if (_files[idx].mergeOptions != options) {
        _files[idx].mergeOptions = options;
        updated = true;
      }
    }
    return updated;
  }
}
