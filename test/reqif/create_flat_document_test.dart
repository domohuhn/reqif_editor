// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter_test/flutter_test.dart';
import 'package:reqif_editor/src/document/document_service.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_io.dart';
import 'package:reqif_editor/src/reqif/flat_document.dart';

void main() {
  final system = DocumentService();
  const inputFile = 'test/data/example1.reqif';

  group('flatten document', () {
    final doc = readReqIFToXML(inputFile, system);
    final parsed = ReqIfDocument.parse(doc);
    test('Headings', () {
      final flat = ReqIfFlatDocument.buildFlatDocument(parsed);
      expect(flat.title, "Requirements test document");
      expect(flat.parts.length, 1);
      final outline = flat.parts.first.outline.toList();
      expect(outline.length, 4);

      expect(outline[0].level, 0);
      expect(outline[0].prefix, "1");
      expect(outline[0].position, 0);
      expect(outline[0].type, ReqIfFlatDocumentElementType.heading);

      expect(outline[1].level, 0);
      expect(outline[1].prefix, "2");
      expect(outline[1].position, 5);
      expect(outline[1].type, ReqIfFlatDocumentElementType.heading);

      expect(outline[2].level, 1);
      expect(outline[2].prefix, "2.1");
      expect(outline[2].position, 6);
      expect(outline[2].type, ReqIfFlatDocumentElementType.heading);

      expect(outline[3].level, 1);
      expect(outline[3].prefix, "2.2");
      expect(outline[3].position, 10);
      expect(outline[3].type, ReqIfFlatDocumentElementType.heading);
    });

    test('Filter Elements - empty strings', () {
      final flat = ReqIfFlatDocument.buildFlatDocument(parsed);
      expect(flat.title, "Requirements test document");
      expect(flat.parts.length, 1);
      expect(flat.parts.first.elements.length, 12);
      expect(flat.parts.first.outline.length, 4);
      List<String> filter = ["", "", "", "", "", "", "", ""];
      flat.parts.first.applyFilter(true, filter);
      final elements = flat.parts.first.elements.toList();
      final outline = flat.parts.first.outline.toList();
      expect(elements.length, 12);
      expect(outline.length, 4);
    });
    test('Filter Elements - empty list', () {
      final flat = ReqIfFlatDocument.buildFlatDocument(parsed);
      expect(flat.title, "Requirements test document");
      expect(flat.parts.length, 1);
      expect(flat.parts.first.elements.length, 12);
      expect(flat.parts.first.outline.length, 4);
      List<String> filter = [];
      flat.parts.first.applyFilter(true, filter);
      final elements = flat.parts.first.elements.toList();
      final outline = flat.parts.first.outline.toList();
      expect(elements.length, 12);
      expect(outline.length, 4);
    });

    test('Filter Elements - too many empty strings', () {
      final flat = ReqIfFlatDocument.buildFlatDocument(parsed);
      expect(flat.title, "Requirements test document");
      expect(flat.parts.length, 1);
      expect(flat.parts.first.elements.length, 12);
      expect(flat.parts.first.outline.length, 4);
      List<String> filter = ["", "", "", "", "", "", "", "", "", "", ""];
      flat.parts.first.applyFilter(true, filter);
      final elements = flat.parts.first.elements.toList();
      final outline = flat.parts.first.outline.toList();
      expect(elements.length, 12);
      expect(outline.length, 4);
    });

    test('Filter Elements - xhtml', () {
      final flat = ReqIfFlatDocument.buildFlatDocument(parsed);
      expect(flat.title, "Requirements test document");
      expect(flat.parts.length, 1);
      expect(flat.parts.first.elements.length, 12);
      List<String> filter = ["", "", "editable", ""];
      flat.parts.first.applyFilter(true, filter);
      final elements = flat.parts.first.elements.toList();
      expect(elements.length, 1);
      expect(elements[0].level, 2);
      expect(elements[0].prefix, "2.2.1");
      expect(elements[0].position, 0);
      expect(elements[0].type, ReqIfFlatDocumentElementType.normal);
    });

    test('Filter Elements - enum 1', () {
      final flat = ReqIfFlatDocument.buildFlatDocument(parsed);
      expect(flat.title, "Requirements test document");
      expect(flat.parts.length, 1);
      final part = flat.parts.first;
      expect(part.elements.length, 12);
      List<String> filter = ["", "", "", "Linux"];
      part.applyFilter(true, filter);
      final elements = part.elements.toList();
      expect(elements.length, 10);
      for (int i = 0; i < 1; ++i) {
        expect(part.mapFilteredPositionToOriginalPosition(elements[i].position),
            i);
      }
      expect(
          part.mapFilteredPositionToOriginalPosition(elements[2].position), 3);
      for (int i = 3; i < 10; ++i) {
        expect(part.mapFilteredPositionToOriginalPosition(elements[i].position),
            i + 2);
      }
    });

    test('Filter Elements - enum 2', () {
      final flat = ReqIfFlatDocument.buildFlatDocument(parsed);
      expect(flat.title, "Requirements test document");
      expect(flat.parts.length, 1);
      final part = flat.parts.first;
      expect(part.elements.length, 12);
      List<String> filter = ["", "", "", "(Linux|Windows)"];
      part.applyFilter(true, filter);
      final elements = part.elements.toList();
      expect(elements.length, 11);
      for (int i = 0; i < 4; ++i) {
        expect(part.mapFilteredPositionToOriginalPosition(elements[i].position),
            i);
      }
      for (int i = 4; i < 11; ++i) {
        expect(part.mapFilteredPositionToOriginalPosition(elements[i].position),
            i + 1);
      }
    });

    test('Filter Headings', () {
      final flat = ReqIfFlatDocument.buildFlatDocument(parsed);
      expect(flat.title, "Requirements test document");
      expect(flat.parts.length, 1);
      List<String> filter = ["", "", "editable", ""];
      flat.parts.first.applyFilter(true, filter);
      final outline = flat.parts.first.outline.toList();
      expect(outline.length, 2);

      expect(outline[0].level, 0);
      expect(outline[0].prefix, "2");
      expect(outline[0].position, 0);
      expect(outline[0].type, ReqIfFlatDocumentElementType.heading);

      expect(outline[1].level, 1);
      expect(outline[1].prefix, "2.2");
      expect(outline[1].position, 0);
      expect(outline[1].type, ReqIfFlatDocumentElementType.heading);
    });

    test('toString', () {
      final flat = ReqIfFlatDocument.buildFlatDocument(parsed);
      expect(flat.title, "Requirements test document");
      expect(flat.parts.length, 1);
      final elements = flat.parts.first.elements.toList();
      expect(elements.length, 12);
      expect(flat.toString(), flatString);
    });

    test('is editable', () {
      final flat = ReqIfFlatDocument.buildFlatDocument(parsed);
      expect(flat.title, "Requirements test document");
      expect(flat.parts.length, 1);
      final elements = flat.parts.first.elements.toList();
      expect(elements.length, 12);
      for (final el in elements) {
        expect(el.isEditable, true);
      }
    });

    test('string escape', () {
      final str = escapeSpecialCharacters(
          '<SPEC-OBJECT LAST-CHANGE="2023-11-22T11:42:13+01:00" IDENTIFIER="_3f12b85a-a5c3-4749-b586-7dd7db436a8b" LONG-NAME="REQ_7  &lt;tag>">');
      expect(str,
          '<SPEC-OBJECT LAST-CHANGE="2023-11-22T11:42:13+01:00" IDENTIFIER="_3f12b85a-a5c3-4749-b586-7dd7db436a8b" LONG-NAME="REQ_7  &lt;tag&gt;">');
    });
  });
}

const flatString = """\
[1] | [0] | 1 | REQ_1 | [Heading] | Introduction | [Windows, Linux, MacOS] | 42 | [Draft] | Initial revision | 43.0 | 2023-11-22T11:42:13+01:00 | true
[1] | [1] |  | REQ_2 | [Information] | This document serves as a test input for the ReqIF-editor. | [Windows, Linux, MacOS] |  | [Draft] | Initial revision |  |  | 
[1] | [2] |  | REQ_3 | [Requirement] | The application must work on the windows operating system. | [Windows] |  | [Draft] | Initial revision |  |  | 
[1] | [3] |  | REQ_4 | [Requirement] | The application must work on the linux operating system. | [Linux] |  | [Draft] | Initial revision |  |  | 
[1] | [4] |  | REQ_5 | [Requirement] | The application must work on the MAC OS operating system. | [MacOS] |  | [Draft] | Initial revision |  |  | 
[1] | [5] | 2 | REQ_6 | [Heading] | Functionality | [Windows, Linux, MacOS] |  | [Draft] | Initial revision |  |  | 
[1] | [6] | 2.1 | REQ_11 | [Heading] | Import and export | [Windows, Linux, MacOS] |  | [Draft] | Initial revision |  |  | 
[1] | [7] |  | REQ_7 | [Requirement] | The program must be able to load files conforming to ReqIf version 1.0. | [Windows, Linux, MacOS] |  | [Draft] | Initial revision |  |  | 
[1] | [8] |  | REQ_8 | [Requirement] | The program must be able to save files conforming to ReqIf version 1.0.Some characters may need to be escaped: [brackets]\tSome non ascii characters: äö | [Windows, Linux, MacOS] |  | [Draft] | Initial revision |  |  | 
[1] | [9] |  | REQ_9 | [Requirement] | A round trip testing strikethrough consisting of loading a file and saving it must produce equivalent output. Only these fields shall be modified:LAST-CHANGECOMMENTSOURCE-TOOL-ID | [Windows, Linux, MacOS] |  | [Draft] | Initial revision |  |  | 
[1] | [10] | 2.2 | REQ_12 | [Heading] | Edit | [Windows, Linux, MacOS] |  | [Draft] | Initial revision |  |  | 
[1] | [11] |  | REQ_10 | [Requirement] | Only contents in columns marked as editable can be modified. | [Windows, Linux, MacOS] |  | [Draft] | Initial revision <tag> |  |  | 
""";
