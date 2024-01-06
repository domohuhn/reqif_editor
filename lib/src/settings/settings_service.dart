// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:reqif_editor/src/settings/last_opened.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';

/// A service that stores and retrieves user settings.
///
/// By default, this class does persist user settings
/// in the local storage.
abstract class SettingsService {
  /// Loads the User's preferred ThemeMode from local or remote storage.
  Future<ThemeMode> themeMode();

  /// Loads the User's preferred line ending configuration when saving files
  /// from local or remote storage.
  Future<LineEndings> lineEndings();

  /// Loads the User's preferred update configuration when saving files
  /// from local or remote storage.
  Future<bool> updateTool();

  /// Loads the User's preferred update configuration when saving files
  /// from local or remote storage.
  Future<bool> updateCreationTime();

  /// Loads the User's preferred update configuration when saving files
  /// from local or remote storage.
  Future<bool> updateUUID();

  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> setThemeMode(ThemeMode theme);

  /// Persists the user's preferred update settings to local or remote storage.
  Future<void> setUpdateTool(bool tool);

  /// Persists the user's preferred update settings to local or remote storage.
  Future<void> setUpdateCreationTime(bool tool);

  /// Persists the user's preferred update settings to local or remote storage.
  Future<void> setUpdateUUID(bool tool);

  /// Persists the user's preferred update settings to local or remote storage.
  Future<void> setLineEndings(LineEndings selected);

  /// Gets the last opened files
  Future<LastOpenedFiles> lastOpenedFiles();

  /// Sets the last opened files
  Future<void> setLastOpenedFiles(LastOpenedFiles files);
}

/// A service that stores and retrieves user settings.
///
/// By default, this class does persist user settings
/// in the local storage.
class LocalSettingsService extends SettingsService {
  final SharedPreferences _preferences;

  LocalSettingsService._create(this._preferences);

  static Future<SettingsService> create() async {
    final preferences = await SharedPreferences.getInstance();
    return LocalSettingsService._create(preferences);
  }

  static const String _keyTheme = 'theme';
  static const String _keyLineEndings = 'lineEndings';
  static const String _keyUpdateDocumentUUID = 'updateUUID';
  static const String _keyUpdateTool = 'updateTool';
  static const String _keyUpdateCreationTime = 'updateTime';

  /// Loads the User's preferred ThemeMode from local or remote storage.
  @override
  Future<ThemeMode> themeMode() async {
    final int? theme = _preferences.getInt(_keyTheme);
    if (theme != null && theme < ThemeMode.values.length) {
      return ThemeMode.values[theme];
    }
    return ThemeMode.system;
  }

  /// Loads the User's preferred line ending configuration when saving files
  /// from local or remote storage.
  @override
  Future<LineEndings> lineEndings() async {
    final int? value = _preferences.getInt(_keyLineEndings);
    if (value != null && value < LineEndings.values.length) {
      return LineEndings.values[value];
    }
    return LineEndings.carriageReturnLinefeed;
  }

  /// Loads the User's preferred update configuration when saving files
  /// from local or remote storage.
  @override
  Future<bool> updateTool() async {
    final bool? value = _preferences.getBool(_keyUpdateTool);
    return value ?? true;
  }

  /// Loads the User's preferred update configuration when saving files
  /// from local or remote storage.
  @override
  Future<bool> updateCreationTime() async {
    final bool? value = _preferences.getBool(_keyUpdateCreationTime);
    return value ?? true;
  }

  /// Loads the User's preferred update configuration when saving files
  /// from local or remote storage.
  @override
  Future<bool> updateUUID() async {
    final bool? value = _preferences.getBool(_keyUpdateDocumentUUID);
    return value ?? true;
  }

  /// Persists the user's preferred ThemeMode to local or remote storage.
  @override
  Future<void> setThemeMode(ThemeMode theme) async {
    await _preferences.setInt(_keyTheme, theme.index);
  }

  /// Persists the user's preferred update settings to local or remote storage.
  @override
  Future<void> setUpdateTool(bool tool) async {
    await _preferences.setBool(_keyUpdateTool, tool);
  }

  /// Persists the user's preferred update settings to local or remote storage.
  @override
  Future<void> setUpdateCreationTime(bool tool) async {
    await _preferences.setBool(_keyUpdateCreationTime, tool);
  }

  /// Persists the user's preferred update settings to local or remote storage.
  @override
  Future<void> setUpdateUUID(bool tool) async {
    await _preferences.setBool(_keyUpdateDocumentUUID, tool);
  }

  /// Persists the user's preferred update settings to local or remote storage.
  @override
  Future<void> setLineEndings(LineEndings selected) async {
    await _preferences.setInt(_keyLineEndings, selected.index);
  }

  Future<void> setDateTimeList(String key, List<DateTime> values) async {
    await _preferences.setStringList(
        key, values.map((e) => e.toIso8601String()).toList());
  }

  Future<void> setStringList(String key, List<String> values) async {
    await _preferences.setStringList(key, values);
  }

  List<String> readStringList(String key) {
    return _preferences.getStringList(key) ?? <String>[];
  }

  List<DateTime> readDateTimeList(String key) {
    return readStringList(key)
        .map((e) => DateTime.tryParse(e) ?? DateTime.now())
        .toList();
  }

  static const String _keyLastOpenedPath = 'lastOpenedPath';
  static const String _keyLastOpenedTitle = 'lastOpenedTitle';
  static const String _keyLastOpenedDate = 'lastOpenedDate';

  /// Gets the last opened files
  @override
  Future<LastOpenedFiles> lastOpenedFiles() async {
    final paths = readStringList(_keyLastOpenedPath);
    final titles = readStringList(_keyLastOpenedTitle);
    final times = readDateTimeList(_keyLastOpenedDate);
    if (paths.length != titles.length || paths.length != times.length) {
      return LastOpenedFiles([]);
    }
    List<FileData> data = [];
    for (int i = 0; i < paths.length; ++i) {
      data.add(FileData(titles[i], paths[i], times[i]));
    }
    return LastOpenedFiles(data);
  }

  /// Sets the last opened files
  @override
  Future<void> setLastOpenedFiles(LastOpenedFiles files) async {
    List<String> paths = [];
    List<String> titles = [];
    List<DateTime> times = [];
    for (final file in files.files) {
      paths.add(file.path);
      titles.add(file.title);
      times.add(file.lastUsed);
    }
    await setStringList(_keyLastOpenedPath, paths);
    await setStringList(_keyLastOpenedTitle, titles);
    await setDateTimeList(_keyLastOpenedDate, times);
  }
}
