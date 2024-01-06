// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter_test/flutter_test.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/document/document_service.dart';
import 'package:reqif_editor/src/settings/settings_controller.dart';
import 'mock_settings_service.dart';

void main() async {
  const inputFile = 'test/data/example1.reqif';

  final system = DocumentService();
  final settingsService = MockSettingsService();
  final settingsController = SettingsController(settingsService);
  await settingsController.loadSettings();

  group('Controller', () {
    test('load file', () async {
      DocumentController controller =
          DocumentController(system, settingsController);
      await controller.loadDocument(inputFile);
      expect(controller.documents.length, 1);
    });
  });
}
