// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/reqif/reqif_attribute_definitions.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';
import 'package:xml/xml.dart' as xml;

/// This class is the base type for children of the XML SPEC-TYPES element
class ReqIfSpecType extends ReqIfIdentifiable {
  /// [node] must have the given tag.
  ///
  /// Children:
  /// SPEC-ATTRIBUTES
  ///   ATTRIBUTE-DEFINITION-XXX
  ///     TYPE
  ///       DATATYPE-DEFINITION-XXX-REF
  ///
  ReqIfSpecType.parse(xml.XmlElement node, ReqIfDocument document,
      ReqIfElementTypes type, String xmlName)
      : super.parse(node, type) {
    if (node.name.local != xmlName) {
      throw ReqIfError(
          'Internal error: wrong node given to ReqIfSpecType.parse\n\n Expected: $xmlName\nActual: ${node.name.local}\n\nNode: $node');
    }
    final outerContent = node.findElements('SPEC-ATTRIBUTES');
    if (outerContent.length != 1) {
      throw ReqIfError(
          "Failed to parse document! Only one SPEC-ATTRIBUTES node is allowed per $xmlName!");
    }
    int i = 0;
    for (final element in outerContent.first.childElements) {
      switch (element.name.local) {
        case ReqIfAttributeEnumDefinition.xmlName:
          children
              .add(ReqIfAttributeEnumDefinition.parse(element, document, i));
        case "ATTRIBUTE-DEFINITION-XHTML":
          children.add(ReqIfAttributeDefinition.parse(element, document, i));
        case "ATTRIBUTE-DEFINITION-STRING":
          children.add(ReqIfAttributeDefinition.parse(element, document, i));
        case "ATTRIBUTE-DEFINITION-INTEGER":
          children.add(ReqIfAttributeDefinition.parse(element, document, i));
        case "ATTRIBUTE-DEFINITION-BOOLEAN":
          children.add(ReqIfAttributeDefinition.parse(element, document, i));
        case "ATTRIBUTE-DEFINITION-DATE":
          children
              .add(ReqIfAttributeDefinition.parse(element, document, i /*  */));
        case "ATTRIBUTE-DEFINITION-REAL":
          children
              .add(ReqIfAttributeDefinition.parse(element, document, i /*  */));
      }
      ++i;
    }
  }

  /// The definition of all attributes in the specification objects.
  Iterable<ReqIfAttributeDefinition> get attributeDefinitions =>
      children.map((e) => e as ReqIfAttributeDefinition);

  /// The number of all attributes in the specification objects.
  int get attributeCount => children.length;

  ReqIfAttributeDefinition operator [](int i) {
    return children[i] as ReqIfAttributeDefinition;
  }
}
