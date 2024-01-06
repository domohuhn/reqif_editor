// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter_test/flutter_test.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/document/document_service.dart';
import 'package:reqif_editor/src/document/navigation_tree_node.dart';
import 'package:reqif_editor/src/settings/settings_controller.dart';
import 'mock_settings_service.dart';

void main() async {
  const inputFile = 'test/data/example1.reqif';

  final system = DocumentService();
  final settingsService = MockSettingsService();
  final settingsController = SettingsController(settingsService);
  await settingsController.loadSettings();

  DocumentController controller =
      DocumentController(system, settingsController);
  await controller.loadDocument(inputFile);

  group('build tree from flat document', () {
    test('build normal tree', () {
      final roots = NavigationTreeNode.buildNavigationTree(controller);
      final outline =
          controller.documents[0].flatDocument.parts.first.outline.toList();

      expect(roots.length, 1);
      expect(roots[0].content, controller.documents[0]);
      expect(roots[0].document, controller.documents[0]);
      expect(roots[0].isFile, true);
      expect(roots[0].isPart, false);
      expect(roots[0].isNode, false);

      expect(roots[0].children.length, 1);
      expect(roots[0].parent, null);
      expect(roots[0].children[0].content,
          controller.documents[0].flatDocument.parts.first);
      expect(roots[0].children[0].part,
          controller.documents[0].flatDocument.parts.first);
      NavigationTreeNode current = roots[0].children[0];

      expect(current.parent, roots[0]);
      expect(current.isFile, false);
      expect(current.isPart, true);
      expect(current.isNode, false);
      expect(current.children.length, 2);
      expect(current.children[0].content, outline[0]);
      expect(current.children[0].element, outline[0]);
      expect(current.children[0].children.length, 0);
      expect(current.children[0].parent, current);
      expect(current.children[0].isFile, false);
      expect(current.children[0].isPart, false);
      expect(current.children[0].isNode, true);
      expect(current.children[1].content, outline[1]);
      expect(current.children[1].element, outline[1]);
      expect(current.children[1].parent, current);
      expect(current.children[1].isFile, false);
      expect(current.children[1].isPart, false);
      expect(current.children[1].isNode, true);
      current = current.children[1];
      expect(current.children.length, 2);
      expect(current.children[0].content, outline[2]);
      expect(current.children[0].element, outline[2]);
      expect(current.children[0].parent, current);
      expect(current.children[0].isFile, false);
      expect(current.children[0].isPart, false);
      expect(current.children[0].isNode, true);
      expect(current.children[1].content, outline[3]);
      expect(current.children[1].element, outline[3]);
      expect(current.children[1].parent, current);
      expect(current.children[1].isFile, false);
      expect(current.children[1].isPart, false);
      expect(current.children[1].isNode, true);
    });
  });
}
