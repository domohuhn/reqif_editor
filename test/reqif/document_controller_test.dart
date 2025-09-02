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

    test('column orders - round trip', () async {
      DocumentController controller =
          DocumentController(system, settingsController);
      await controller.loadDocument(inputFile);
      expect(controller.documents.length, 1);
      final rv = controller.documents[0].columnOrderToJson();
      expect(rv, '{"0":[0,1,2,3,4,5,6,7,8,9,10]}');

      const input = '{"0":[10,9,8,7,6,5,4,3,2,1,0]}';
      controller.documents[0].initializePartModels(
          columnOrder: input, columnVisibility: "", mergeData: "");
      final rv2 = controller.documents[0].columnOrderToJson();
      expect(rv2, input);

      // verify no exceptions are thrown on malformed input
      const input2 = 'aa';
      controller.documents[0].initializePartModels(
          columnOrder: input2, columnVisibility: "", mergeData: "");
      const input3 = '';
      controller.documents[0].initializePartModels(
          columnOrder: input3, columnVisibility: "", mergeData: "");
      const input4 = '{"0":';
      controller.documents[0].initializePartModels(
          columnOrder: input4, columnVisibility: "", mergeData: "");
    });
  });
}
