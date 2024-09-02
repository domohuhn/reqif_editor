// Copyright 2024, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/reqif/reqif_attribute_values.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';
import 'package:xml/xml.dart' as xml;

/// Holds the default value if given
class ReqIfAttributeDefaultValue {
  static const String xmlName = "DEFAULT-VALUE";

  ReqIfAttributeDefaultValue.parse(
      xml.XmlElement node, ReqIfDocument document, ReqIfIdentifiable parent) {
    if (node.name.local != xmlName) {
      throw ReqIfError(
          'Internal error: wrong node given to ReqIfAttributeDefaultValue.parse\n\n Expected: $xmlName\nActual: ${node.name.local}\n\nNode: $node');
    }
    final children = node.childElements;
    if (children.length > 1) {
      throw ReqIfError(
          "Failed to parse document! Only one ATTRIBUTE-VALUE node is allowed per $xmlName!");
    }

    for (final inner in children) {
      switch (inner.localName) {
        case ReqIfAttributeValueString.xmlName:
          value = ReqIfAttributeValueString.parse(
              parent: parent, element: inner, document: document, link: parent);
        case ReqIfAttributeValueInteger.xmlName:
          value = ReqIfAttributeValueInteger.parse(
              parent: parent, element: inner, document: document, link: parent);
        case ReqIfAttributeValueEnum.xmlName:
          value = ReqIfAttributeValueEnum.parse(
              parent: parent, element: inner, document: document, link: parent);
        case ReqIfAttributeValueXhtml.xmlName:
          value = ReqIfAttributeValueXhtml.parse(
              parent: parent, element: inner, document: document, link: parent);
        case ReqIfAttributeValueDate.xmlName:
          value = ReqIfAttributeValueDate.parse(
              parent: parent, element: inner, document: document, link: parent);
        case ReqIfAttributeValueReal.xmlName:
          value = ReqIfAttributeValueReal.parse(
              parent: parent, element: inner, document: document, link: parent);
        case ReqIfAttributeValueBool.xmlName:
          value = ReqIfAttributeValueBool.parse(
              parent: parent, element: inner, document: document, link: parent);
      }
    }
  }

  /// The default value - may be null
  ReqIfAttributeValue? value;
}
