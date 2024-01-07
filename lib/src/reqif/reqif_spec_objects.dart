// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/reqif/reqif_attribute_definitions.dart';
import 'package:reqif_editor/src/reqif/reqif_attribute_values.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_data_types.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';
import 'package:reqif_editor/src/reqif/reqif_spec_object_type.dart';
import 'package:xml/xml.dart' as xml;

/// This class holds a single specification object defined in the reqif file.
class ReqIfSpecificationObject extends ReqIfIdentifiable {
  static const String xmlName = 'SPEC-OBJECT';
  static const String _xmlNameType = 'TYPE';
  static const String _xmlNameSpecObjectTypeRef = 'SPEC-OBJECT-TYPE-REF';

  /// Constructs an instance of this type by parsing an existing ReqIF document.
  /// May throw an error if links cannot be resolved or if the the document
  /// is built not according to the spec.
  ///
  /// [node] must be of type SPEC-OBJECT.
  ///
  /// [document] is a reference to the parent document.
  ReqIfSpecificationObject.parse(xml.XmlElement element, ReqIfDocument document)
      : super.parse(element, ReqIfElementTypes.specificationObject) {
    _specificationObjectTypeId = getInnerTextOfGrandChildElements(
        node, _xmlNameType, _xmlNameSpecObjectTypeRef);
    final link = document.resolveLink(_specificationObjectTypeId);
    if (link is! ReqIfSpecificationObjectType) {
      throw ReqIfError(
          "Failed to parse document! Definition reference $_specificationObjectTypeId was not resolved correctly!\n\n$node");
    }
    _specificationObjectType = link;
    buildChildObjects(
        element: element,
        firstChildTag: 'VALUES',
        builder: (inner) {
          switch (inner.name.local) {
            case "ATTRIBUTE-VALUE-STRING":
              children.add(ReqIfAttributeValueSimple.parse(
                  parent: this, element: inner, document: document));
            case "ATTRIBUTE-VALUE-ENUMERATION":
              children.add(ReqIfAttributeValueEnum.parse(
                  parent: this, element: inner, document: document));
            case ReqIfAttributeValueXhtml.xmlName:
              children.add(ReqIfAttributeValueXhtml.parse(
                  parent: this, element: inner, document: document));
          }
        });
    children.sort((a, b) {
      a as ReqIfAttributeValue;
      b as ReqIfAttributeValue;
      return a.column.compareTo(b.column);
    });
  }

  ReqIfAttributeValue? operator [](int column) {
    ReqIfAttributeValue? rv;
    if (column < children.length) {
      rv = children[column] as ReqIfAttributeValue;
    }
    if (rv == null || rv.column != column) {
      for (int i = 0; i < children.length; ++i) {
        if ((children[i] as ReqIfAttributeValue).column == column) {
          return children[i] as ReqIfAttributeValue;
        }
      }
      return null;
    }
    return rv;
  }

  late String _specificationObjectTypeId;
  late ReqIfSpecificationObjectType _specificationObjectType;

  String get specificationObjectTypeId => _specificationObjectTypeId;
  ReqIfSpecificationObjectType get specificationObjectType =>
      _specificationObjectType;

  ReqIfSpecificationObjectType get objectType => _specificationObjectType;
  Iterable<ReqIfAttributeDefinition> get attributeDefinitions =>
      specificationObjectType.attributeDefinitions;
  Iterable<ReqIfAttributeValue> get values =>
      children.map((e) => e as ReqIfAttributeValue);

  /// Creates an unformatted string representation of the object.
  @override
  String toString() {
    final buffer = StringBuffer();
    bool notFirst = false;
    for (final value in values) {
      if (notFirst) {
        buffer.write(' | ');
      }
      buffer.write(value);
      notFirst = true;
    }
    return buffer.toString();
  }
}
