// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter_test/flutter_test.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/document/document_remapping.dart';
import 'package:reqif_editor/src/document/document_service.dart';
import 'package:reqif_editor/src/settings/settings_controller.dart';
import 'dart:convert';
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
      expect(rv, '{"0":[0,1,2,3,4,5,6,7,8,9]}');

      const input = '{"0":[9,8,7,6,5,4,3,2,1,0]}';
      controller.documents[0].columnOrderFromJson(input);
      final rv2 = controller.documents[0].columnOrderToJson();
      expect(rv2, input);

      // verify no exceptions are thrown on malformed input
      const input2 = 'aa';
      controller.documents[0].columnOrderFromJson(input2);
      const input3 = '';
      controller.documents[0].columnOrderFromJson(input3);
      const input4 = '{"0":';
      controller.documents[0].columnOrderFromJson(input4);
    });
  });

  group('Column Remapping', () {
    test('serialize column order - one part', () {
      final order = ColumnMappings(5);
      expect(order.orderToJsonFragment(1), '"1":[0,1,2,3,4]');
      order.moveColumn(2, 1);
      expect(order.orderToJsonFragment(3), '"3":[0,1,3,2,4]');
      order.resetOrder();
      expect(order.orderToJsonFragment(2), '"2":[0,1,2,3,4]');
    });

    test('deserialize column order - one part', () {
      final order = ColumnMappings(5);
      final input =
          '{"1":[0,1,2,3,4],"2":["0"],"0":[4,3,2,1,0],"4":[0,1,2,3,3],"3":[0,1,2,3,"a"],"5":[0,1,2,3,5]}';
      final data = jsonDecode(input);

      order.orderFromJson(data, 0);
      for (int i = 0; i < 5; ++i) {
        expect(order.remap(i), 4 - i);
      }

      for (int i = 1; i < 6; ++i) {
        order.orderFromJson(data, i);
        for (int i = 0; i < 5; ++i) {
          expect(order.remap(i), i, reason: "$i failed");
        }
      }
    });

    test('serialize visibility - one part', () {
      final order = ColumnMappings(5);
      expect(
          order.visibilityToJsonFragment(1), '"1":[true,true,true,true,true]');
      expect(order.visibleColumnCount(), 5);
      order.setVisibility(0, false);
      expect(order.visibleColumnCount(), 4);
      order.setVisibility(3, false);
      expect(order.visibleColumnCount(), 3);
      expect(order.visibilityToJsonFragment(4),
          '"4":[false,true,true,false,true]');

      order.resetVisibility();
      expect(order.visibleColumnCount(), 5);
      expect(
          order.visibilityToJsonFragment(5), '"5":[true,true,true,true,true]');
    });

    test('deserialize visibility - one part', () {
      final order = ColumnMappings(3);
      final input =
          '{"0":[false,true,true],"1":[false,true,false],"2":[false,false,false],"3":[true,true,true],"4":[true],"5":[0,1,1]}';

      final data = jsonDecode(input);
      order.visibilityFromJson(data, 0);
      expect(order.visibleColumnCount(), 2);
      order.visibilityFromJson(data, 1);
      expect(order.visibleColumnCount(), 1);
      order.visibilityFromJson(data, 2);
      expect(order.visibleColumnCount(), 0);

      for (int i = 3; i < 6; ++i) {
        order.visibilityFromJson(data, i);
        expect(order.visibleColumnCount(), 3);
      }
    });
  });
}
