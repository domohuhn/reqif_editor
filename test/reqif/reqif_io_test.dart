// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter_test/flutter_test.dart';
import 'package:reqif_editor/src/document/document_service.dart';
import 'package:reqif_editor/src/reqif/reqif_attribute_definitions.dart';
import 'package:reqif_editor/src/reqif/reqif_attribute_values.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_data_types.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_io.dart';
import 'package:xml/xml.dart' as xml;

void main() {
  final system = DocumentService();
  const inputFile = 'test/data/example1.reqif';
  const outputFile = 'test/data/example1_testoutput.reqif';
  final contents = system.readFileSync(inputFile);
  group('Roundtrip', () {
    test('Read and write raw XML', () {
      final doc = readReqIFToXML(inputFile, system);
      writeXMLToFile(outputFile, doc, system);
      final compare = system.readFileSync(outputFile);
      expect(compare, contents);
    });
  });

  group('Datatypes', () {
    final doc = readReqIFToXML(inputFile, system);
    var parsed = ReqIfDocument.parse(doc);
    test('count', () {
      expect(parsed.dataTypes.length, 1);
      expect(parsed.dataTypes.first.types.length, 9);
    });

    test('string', () {
      final type = parsed.dataTypes.first.types.first;
      expect(type.type, ReqIfElementTypes.datatypeDefinitionString);
      if (type is ReqIfDataTypeString) {
        expect(type.identifier, "_6bb0fb91-a2b8-4003-ad3f-9ee92d2552cc");
        expect(type.lastChange.toIso8601String(), "2023-11-22T10:42:13.000Z");
        expect(type.maxLength, 1024);
        expect(type.name, "String");
      } else {
        fail("Wrong data type");
      }
    });

    test('xhtml', () {
      final type = parsed.dataTypes.first.types[1];
      expect(type.type, ReqIfElementTypes.datatypeDefinitionXhtml);
      if (type is ReqIfDataTypeXhtml) {
        expect(type.identifier, "_81c063b5-1b5a-4579-bc3b-52d5909eaa4d");
        expect(type.lastChange.toIso8601String(), "2023-11-22T10:42:13.000Z");
        expect(type.name, "Xhtml");
      } else {
        fail("Wrong data type");
      }
    });

    test('enum', () {
      final type = parsed.dataTypes.first.types[2];
      expect(type.type, ReqIfElementTypes.datatypeDefinitionEnum);
      if (type is ReqIfDataTypeEnum) {
        expect(type.identifier, "_151231c6-6677-43ca-aa6c-a8130868fbc5");
        expect(type.lastChange.toIso8601String(), "2023-11-22T10:42:13.000Z");
        expect(type.name, "TypeReq");
        expect(type.values, 3);
        expect(type.value(0), "Heading");
        expect(type.value(1), "Information");
        expect(type.value(2), "Requirement");
      } else {
        fail("Wrong data type");
      }
    });

    test('int', () {
      final type = parsed.dataTypes.first.types[5];
      expect(type.type, ReqIfElementTypes.datatypeDefinitionInteger);
      if (type is ReqIfDataTypeInt) {
        expect(type.identifier, "_7e2e7ce9-99ee-4a30-86e9-2576580f426c");
        expect(type.lastChange.toIso8601String(), "2023-11-22T10:42:13.000Z");
        expect(type.name, "Number1");
        expect(type.maximum, 127);
        expect(type.minimum, -128);
      } else {
        fail("Wrong data type");
      }
    });
  });

  group('Columns', () {
    final doc = readReqIFToXML(inputFile, system);
    var parsed = ReqIfDocument.parse(doc);
    test('count', () {
      expect(parsed.specificationObjectTypes.length, 1);
      expect(parsed.specificationObjectTypes.first.children.length, 10);
    });

    test('xhtml 1', () {
      final col = parsed.specificationObjectTypes.first.children[0];
      expect(col.type, ReqIfElementTypes.attributeDefinition);
      if (col is ReqIfAttributeDefinition) {
        expect(col.identifier, "_2ae87137-93fe-471f-a4b7-471ad94d1741");
        expect(col.lastChange.toIso8601String(), "2023-11-22T10:42:13.000Z");
        expect(col.name, "Object ID");
        expect(col.dataType, ReqIfElementTypes.datatypeDefinitionXhtml);
        expect(
            col.referencedDataTypeId, "_81c063b5-1b5a-4579-bc3b-52d5909eaa4d");
        expect(col.dataTypeDefinition.identifier,
            "_81c063b5-1b5a-4579-bc3b-52d5909eaa4d");
        expect(col.isEditable, false);
      } else {
        fail("Wrong data type");
      }
    });

    test('enum 2', () {
      final col = parsed.specificationObjectTypes.first.children[1];
      expect(col.type, ReqIfElementTypes.attributeDefinition);
      if (col is ReqIfAttributeEnumDefinition) {
        expect(col.identifier, "_005f65f2-f2fa-4457-927a-1c6776b6709b");
        expect(col.lastChange.toIso8601String(), "2023-11-22T10:42:13.000Z");
        expect(col.name, "Type");
        expect(col.dataType, ReqIfElementTypes.datatypeDefinitionEnum);
        expect(
            col.referencedDataTypeId, "_151231c6-6677-43ca-aa6c-a8130868fbc5");
        expect(col.dataTypeDefinition.identifier,
            "_151231c6-6677-43ca-aa6c-a8130868fbc5");
        expect(col.isMultiValued, false);
        expect(col.isEditable, false);
      } else {
        fail("Wrong data type");
      }
    });
  });

  group('spec objects', () {
    test('count', () {
      final doc = readReqIFToXML(inputFile, system);
      var parsed = ReqIfDocument.parse(doc);
      expect(parsed.specificationObjects.length, 12);
    });

    test('update enum value', () {
      final doc = readReqIFToXML(inputFile, system);
      var parsed = ReqIfDocument.parse(doc);
      ReqIfAttributeValueEnum val = parsed
          .specificationObjects.first.children[1] as ReqIfAttributeValueEnum;
      expect(val.length, 1);
      expect(val.isEditable, false);
      expect(val.isMultiValued, false);
      expect(val.value(0), "Heading");

      ReqIfAttributeValueEnum val2 = parsed
          .specificationObjects.first.children[3] as ReqIfAttributeValueEnum;
      expect(val2.length, 3);
      expect(val2.isEditable, false);
      expect(val2.isMultiValued, true);
      expect(val2.value(0), "Windows");
      expect(val2.value(1), "Linux");
      expect(val2.value(2), "MacOS");
      expect(val2.validValues, ['Windows', 'MacOS', 'Linux']);
      val2.setValue(2, val2.validValues.first);
      expect(val2.value(0), "Windows");
      expect(val2.value(1), "Linux");
      expect(val2.value(2), "Windows");

      ReqIfAttributeValueEnum val3 = parsed
          .specificationObjects.first.children[5] as ReqIfAttributeValueEnum;
      expect(val3.length, 1);
      expect(val3.isEditable, true);
      expect(val3.isMultiValued, false);
      expect(val3.value(0), "Draft");
      expect(val3.validValues, [
        'Accepted',
        'Rejected',
        'Draft',
        'Review Üä',
        'Clarification-needed'
      ]);
      val3.setValue(0, val3.validValues.first);
      expect(val3.value(0), "Accepted");
    });

    test('add enum value', () {
      final doc = readReqIFToXML(inputFile, system);
      var parsed = ReqIfDocument.parse(doc);
      ReqIfAttributeValueEnum val = parsed
          .specificationObjects.first.children[3] as ReqIfAttributeValueEnum;
      expect(val.length, 3);
      expect(val.isEditable, false);
      expect(val.isMultiValued, true);
      expect(val.value(0), "Windows");
      expect(val.value(1), "Linux");
      expect(val.value(2), "MacOS");
      expect(val.validValues, ['Windows', 'MacOS', 'Linux']);
      val.addValue(val.validValues.first);
      expect(val.length, 4);
      expect(val.value(0), "Windows");
      expect(val.value(1), "Linux");
      expect(val.value(2), "MacOS");
      expect(val.value(3), "Windows");
      expect(
          val.node.toString().replaceAll('\r\n', '\n'),
          """<ATTRIBUTE-VALUE-ENUMERATION>
<DEFINITION>
<ATTRIBUTE-DEFINITION-ENUMERATION-REF>_c49cf6e2-96f7-477e-a5af-57eeafafb481</ATTRIBUTE-DEFINITION-ENUMERATION-REF>
</DEFINITION>
<VALUES>
<ENUM-VALUE-REF>_a8f5266e-4330-4660-951e-0e8f22822f44</ENUM-VALUE-REF>
<ENUM-VALUE-REF>_4a487949-2d34-43b2-a5dc-dea4180e3079</ENUM-VALUE-REF>
<ENUM-VALUE-REF>_5d64b5c0-1b13-483a-b0fe-279442fe1c30</ENUM-VALUE-REF>
<ENUM-VALUE-REF>_a8f5266e-4330-4660-951e-0e8f22822f44</ENUM-VALUE-REF>
</VALUES>
</ATTRIBUTE-VALUE-ENUMERATION>"""
              .replaceAll('\r\n', '\n'));
    });

    test('remove enum value', () {
      final doc = readReqIFToXML(inputFile, system);
      var parsed = ReqIfDocument.parse(doc);
      ReqIfAttributeValueEnum val = parsed
          .specificationObjects.first.children[3] as ReqIfAttributeValueEnum;
      expect(val.length, 3);
      expect(val.isEditable, false);
      expect(val.isMultiValued, true);
      expect(val.value(0), "Windows");
      expect(val.value(1), "Linux");
      expect(val.value(2), "MacOS");
      expect(val.validValues, ['Windows', 'MacOS', 'Linux']);
      val.removeValue(1);
      expect(val.length, 2);
      expect(val.value(0), "Windows");
      expect(val.value(1), "MacOS");
      expect(
          val.node.toString().replaceAll('\r\n', '\n'),
          """<ATTRIBUTE-VALUE-ENUMERATION>
<DEFINITION>
<ATTRIBUTE-DEFINITION-ENUMERATION-REF>_c49cf6e2-96f7-477e-a5af-57eeafafb481</ATTRIBUTE-DEFINITION-ENUMERATION-REF>
</DEFINITION>
<VALUES>
<ENUM-VALUE-REF>_a8f5266e-4330-4660-951e-0e8f22822f44</ENUM-VALUE-REF>
<ENUM-VALUE-REF>_5d64b5c0-1b13-483a-b0fe-279442fe1c30</ENUM-VALUE-REF>
</VALUES>
</ATTRIBUTE-VALUE-ENUMERATION>"""
              .replaceAll('\r\n', '\n'));
    });

    test('update xhtml value', () {
      final doc = readReqIFToXML(inputFile, system);
      var parsed = ReqIfDocument.parse(doc);
      ReqIfAttributeValueXhtml val = parsed
          .specificationObjects.first.children[0] as ReqIfAttributeValueXhtml;
      expect(val.namespacePrefixForValue, "reqif-xhtml");
      expect(
          val.element.toString().replaceAll('\r\n', '\n'),
          '<ATTRIBUTE-VALUE-XHTML>\n'
          '<DEFINITION>\n'
          '<ATTRIBUTE-DEFINITION-XHTML-REF>_2ae87137-93fe-471f-a4b7-471ad94d1741</ATTRIBUTE-DEFINITION-XHTML-REF>\n'
          '</DEFINITION>\n'
          '<THE-VALUE><reqif-xhtml:div>REQ_1<reqif-xhtml:br/></reqif-xhtml:div></THE-VALUE>\n'
          '</ATTRIBUTE-VALUE-XHTML>');
      expect(val.value.toString(),
          "<reqif-xhtml:div>REQ_1<reqif-xhtml:br/></reqif-xhtml:div>");
      xml.XmlBuilder builder = xml.XmlBuilder();
      builder.element('reqif-xhtml:p', nest: () {
        builder.text('BLLLLLAAAA');
        builder.element('reqif-xhtml:br');
      });
      final next = builder.buildDocument();
      assert(next.childElements.length == 1);
      val.value = next.firstElementChild!;
      expect(
          val.element.toString().replaceAll('\r\n', '\n'),
          '<ATTRIBUTE-VALUE-XHTML>\n'
          '<DEFINITION>\n'
          '<ATTRIBUTE-DEFINITION-XHTML-REF>_2ae87137-93fe-471f-a4b7-471ad94d1741</ATTRIBUTE-DEFINITION-XHTML-REF>\n'
          '</DEFINITION>\n'
          '<THE-VALUE><reqif-xhtml:p>BLLLLLAAAA<reqif-xhtml:br/></reqif-xhtml:p></THE-VALUE>\n'
          '</ATTRIBUTE-VALUE-XHTML>');
      expect(val.value.toString(),
          "<reqif-xhtml:p>BLLLLLAAAA<reqif-xhtml:br/></reqif-xhtml:p>");
      writeXMLToFile(outputFile, doc, system);
    });
  });

  group('specifications', () {
    final doc = readReqIFToXML(inputFile, system);
    var parsed = ReqIfDocument.parse(doc);
    test('count', () {
      expect(parsed.specifications.length, 1);
      expect(parsed.specifications.first.children.length, 2);
    });
  });
}
