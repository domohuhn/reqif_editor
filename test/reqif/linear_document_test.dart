// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter_test/flutter_test.dart';
import 'package:reqif_editor/src/document/document_service.dart';
import 'package:reqif_editor/src/reqif/flat_document.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_io.dart';

void main() {
  final system = DocumentService();
  const inputFile = 'test/data/example5_doors_export.reqif';
  group('Linear Document', () {
    final doc = readReqIFToXML(inputFile, system);
    var parsed = ReqIfDocument.parse(doc);
    test('Filter', () {
      final linear = ReqIfFlatDocument.buildFlatDocument(parsed);
      expect(linear.partCount, 1);
      final part = linear.parts.first;
      part.applyFilter(true, ["", "", "chap", "", "", "", ""]);
      expect(part.filteredOutline.length, 1);
      expect(part.filteredOutline.first.prefix, "3");
      expect(part.elements.length, 2);
      expect(part.elements.first.toString(),
          "[0] | 3 | REQ_13 | [Heading] | Additional Chapter |  | [Windows, Linux, MacOS] |  | [Draft] | Initial revision |  |  | ");
    });

    test('Filter', () {
      final linear = ReqIfFlatDocument.buildFlatDocument(parsed);
      expect(linear.partCount, 1);
      final part = linear.parts.first;
      part.applyFilter(true, ["", "", "chap", "", "", "", ""], columnsToOr: []);
      expect(part.filteredOutline.length, 1);
      expect(part.filteredOutline.first.prefix, "3");
      expect(part.elements.length, 2);
      expect(part.elements.first.toString(),
          "[0] | 3 | REQ_13 | [Heading] | Additional Chapter |  | [Windows, Linux, MacOS] |  | [Draft] | Initial revision |  |  | ");
    });

    test('Filter - merged', () {
      final linear = ReqIfFlatDocument.buildFlatDocument(parsed);
      expect(linear.partCount, 1);
      final part = linear.parts.first;
      part.applyFilter(true, ["", "", "app", "app", "", "", ""],
          columnsToOr: [2, 3]);
      expect(part.filteredOutline.length, 1);
      expect(part.filteredOutline.first.prefix, "1");
      expect(part.elements.length, 3);
      expect(part.elements.first.toString(),
          "[0] |  | REQ_3 | [Requirement] |  | The application must work on the windows operating system. | [Windows] |  | [Draft] | Initial revision |  |  | ");
    });
  });
}
