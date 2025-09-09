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
      linear.parts.first.applyFilter(true, ["", "", "chap", "", "", "", ""]);
      expect(linear.parts.first.filteredOutline.length, 1);
      expect(linear.parts.first.filteredOutline.first.prefix, "3");
    });
  });
}
