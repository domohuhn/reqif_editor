// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter_test/flutter_test.dart';
import 'package:reqif_editor/src/document/document_service.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_io.dart';

void main() {
  group('Header', () {
    final system = DocumentService();
    const inputFile = 'test/data/example1.reqif';
    test('update title', () {
      final doc = readReqIFToXML(inputFile, system);
      var parsed = ReqIfDocument.parse(doc);
      expect(parsed.header.title, "Requirements test document");
      const newValue = "New Title";
      parsed.header.title = newValue;
      expect(parsed.header.title, newValue);
    });

    test('version immutable', () {
      final doc = readReqIFToXML(inputFile, system);
      var parsed = ReqIfDocument.parse(doc);
      expect(parsed.header.reqIfVersion, "1.0");
    });

    test('update tool id', () {
      final doc = readReqIFToXML(inputFile, system);

      var parsed = ReqIfDocument.parse(doc);
      expect(parsed.header.toolId, "ReqIF Editor Version 1.0");
      const newValue = "New Value";
      parsed.header.toolId = newValue;
      expect(parsed.header.toolId, newValue);
    });

    test('update source tool id', () {
      final doc = readReqIFToXML(inputFile, system);

      var parsed = ReqIfDocument.parse(doc);
      expect(
          parsed.header.sourceToolId, "com.github.reqif_editor.reqif_editor");
      const newValue = "New Value";
      parsed.header.sourceToolId = newValue;
      expect(parsed.header.sourceToolId, newValue);
    });

    test('update comment', () {
      final doc = readReqIFToXML(inputFile, system);

      var parsed = ReqIfDocument.parse(doc);
      expect(parsed.header.comment, "Test document for ReqIF editor");
      const newValue = "New Value";
      parsed.header.comment = newValue;
      expect(parsed.header.comment, newValue);

      parsed.header.comment = null;
      expect(parsed.header.comment, null);

      parsed.header.comment = newValue;
      expect(parsed.header.comment, newValue);
    });

    test('update repository id', () {
      final doc = readReqIFToXML(inputFile, system);

      var parsed = ReqIfDocument.parse(doc);
      expect(parsed.header.repositoryId, null);
      const newValue = "New Value";
      parsed.header.repositoryId = newValue;
      expect(parsed.header.repositoryId, newValue);
    });

    test('update creationTime', () {
      final doc = readReqIFToXML(inputFile, system);
      var parsed = ReqIfDocument.parse(doc);
      var value = DateTime.utc(2023, 11, 22, 10, 42, 13);
      expect(parsed.header.creationTime, value);
      var newValue = DateTime(2024, 11, 22, 11, 42, 13);
      parsed.header.creationTime = newValue;
      expect(parsed.header.creationTime, newValue);
    });

    test('update id', () {
      final doc = readReqIFToXML(inputFile, system);
      var parsed = ReqIfDocument.parse(doc);
      const original = "_5cc5b3f8-461b-4317-8908-f9efb35f3bcb";
      expect(parsed.header.identifier, original);
      parsed.updateDocumentId();
      expect(parsed.header.identifier == original, false);
    });
  });
}
