// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/last_opened/last_opened.dart';

import 'settings_service.dart';

/// A class that many Widgets can interact with to read user settings, update
/// user settings, or listen to user settings changes.
///
/// Also holds the list of last opened files.
class SettingsController with ChangeNotifier {
  SettingsController(this._settingsService);

  final SettingsService _settingsService;

  late ThemeMode _themeMode;

  late LineEndings _lineEndings;
  late bool _updateDocumentUUID;
  late bool _updateTool;
  late bool _updateCreationTime;
  late LastOpenedFiles _files;

  ThemeMode get themeMode => _themeMode;
  LineEndings get lineEndings => _lineEndings;
  bool get updateDocumentUUID => _updateDocumentUUID;
  bool get updateTool => _updateTool;
  bool get updateCreationTime => _updateCreationTime;
  Iterable<FileData> get lastOpenedFiles => _files.files;

  /// Load the user's settings from the SettingsService. It may load from a
  /// local database or the internet.
  Future<void> loadSettings() async {
    _themeMode = await _settingsService.themeMode();
    _updateDocumentUUID = await _settingsService.updateUUID();
    _updateTool = await _settingsService.updateTool();
    _updateCreationTime = await _settingsService.updateCreationTime();
    _lineEndings = await _settingsService.lineEndings();
    _files = await _settingsService.lastOpenedFiles();
    notifyListeners();
  }

  /// Update and persist the ThemeMode based on the user's selection.
  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;
    if (newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    await _settingsService.setThemeMode(newThemeMode);
  }

  /// Update and persist the LineEndings based on the user's selection.
  Future<void> updateLineEndings(LineEndings? newLineEndings) async {
    if (newLineEndings == null) return;
    if (newLineEndings == _lineEndings) return;
    _lineEndings = newLineEndings;
    notifyListeners();
    await _settingsService.setLineEndings(newLineEndings);
  }

  /// Update and persist the file save settings based on the user's selection.
  Future<void> updateUpdateDocumentUUID(bool? newValue) async {
    if (newValue == null) return;
    if (newValue == _updateDocumentUUID) return;
    _updateDocumentUUID = newValue;
    notifyListeners();
    await _settingsService.setUpdateUUID(newValue);
  }

  /// Update and persist the file save settings based on the user's selection.
  Future<void> updateUpdateTool(bool? newValue) async {
    if (newValue == null) return;
    if (newValue == _updateTool) return;
    _updateTool = newValue;
    notifyListeners();
    await _settingsService.setUpdateTool(newValue);
  }

  /// Update and persist the file save settings based on the user's selection.
  Future<void> updateUpdateCreationTime(bool? newValue) async {
    if (newValue == null) return;
    if (newValue == _updateCreationTime) return;
    _updateCreationTime = newValue;
    notifyListeners();
    await _settingsService.setUpdateCreationTime(newValue);
  }

  /// Updates and persists the file save settings based on the user's selection.
  Future<void> addOpenedFile(String path, String title) async {
    if (path.isEmpty || title.isEmpty) return;
    _files.addFile(title, path);
    await _settingsService.setLastOpenedFiles(_files);
    notifyListeners();
  }

  /// Updates and persists the column order of the file.
  Future<void> updateFileColumnOrder(String path, String order) async {
    if (path.isEmpty) return;
    if (_files.updateColumnOrder(path, order)) {
      await _settingsService.setLastOpenedFiles(_files);
    }
    notifyListeners();
  }

  /// Gets the file column order for a given path if present
  String fileColumnOrder(String path) {
    for (final f in _files.files) {
      if (f.path == path) {
        return f.columnOrder;
      }
    }
    return "{}";
  }
}
