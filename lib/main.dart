// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';

import 'package:reqif_editor/src/app.dart';
import 'package:reqif_editor/src/document/document_service.dart';
import 'package:reqif_editor/src/settings/settings_controller.dart';
import 'package:reqif_editor/src/settings/settings_service.dart';
import 'package:reqif_editor/src/document/document_controller.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = await LocalSettingsService.create();
  final settingsController = SettingsController(settingsService);
  final documentService = DocumentService();
  final documentController =
      DocumentController(documentService, settingsController);

  await settingsController.loadSettings();

  final app = ReqIfEditorApp(
      settingsController: settingsController,
      documentController: documentController);

  runApp(app);
}
