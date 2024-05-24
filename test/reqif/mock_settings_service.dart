// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/last_opened/last_opened.dart';
import 'package:reqif_editor/src/settings/settings_service.dart';

class MockSettingsService extends SettingsService {
  @override
  Future<ThemeMode> themeMode() async => ThemeMode.dark;

  @override
  Future<LineEndings> lineEndings() async => LineEndings.linefeed;

  @override
  Future<bool> updateTool() async => true;

  @override
  Future<bool> updateCreationTime() async => true;

  @override
  Future<bool> updateUUID() async => true;

  @override
  Future<void> setThemeMode(ThemeMode theme) async => true;

  @override
  Future<void> setUpdateTool(bool tool) async => true;

  @override
  Future<void> setUpdateCreationTime(bool tool) async => true;

  @override
  Future<void> setUpdateUUID(bool tool) async => true;

  @override
  Future<void> setLineEndings(LineEndings selected) async => true;

  @override
  Future<LastOpenedFiles> lastOpenedFiles() async {
    return LastOpenedFiles([]);
  }

  @override
  Future<void> setLastOpenedFiles(LastOpenedFiles files) async {}
}
