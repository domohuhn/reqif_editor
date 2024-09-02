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
  static const String _xmlValues = 'VALUES';
  final ReqIfDocument document;

  /// Constructs an instance of this type by parsing an existing ReqIF document.
  /// May throw an error if links cannot be resolved or if the the document
  /// is built not according to the spec.
  ///
  /// [node] must be of type SPEC-OBJECT.
  ///
  /// [document] is a reference to the parent document.
  ReqIfSpecificationObject.parse(xml.XmlElement element, this.document)
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
        firstChildTag: _xmlValues,
        builder: (inner) {
          switch (inner.name.local) {
            case ReqIfAttributeValueString.xmlName:
              children.add(ReqIfAttributeValueString.parse(
                  parent: this, element: inner, document: document));
            case ReqIfAttributeValueInteger.xmlName:
              children.add(ReqIfAttributeValueInteger.parse(
                  parent: this, element: inner, document: document));
            case ReqIfAttributeValueEnum.xmlName:
              children.add(ReqIfAttributeValueEnum.parse(
                  parent: this, element: inner, document: document));
            case ReqIfAttributeValueXhtml.xmlName:
              children.add(ReqIfAttributeValueXhtml.parse(
                  parent: this, element: inner, document: document));
            case ReqIfAttributeValueDate.xmlName:
              children.add(ReqIfAttributeValueDate.parse(
                  parent: this, element: inner, document: document));
            case ReqIfAttributeValueReal.xmlName:
              children.add(ReqIfAttributeValueReal.parse(
                  parent: this, element: inner, document: document));
            case ReqIfAttributeValueBool.xmlName:
              children.add(ReqIfAttributeValueBool.parse(
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
  int get columnCount => attributeDefinitions.length;
  Iterable<ReqIfAttributeValue> get values =>
      children.map((e) => e as ReqIfAttributeValue);

  /// Creates an unformatted string representation of the object.
  @override
  String toString() {
    final buffer = StringBuffer();
    bool notFirst = false;
    for (var i = 0; i < columnCount; ++i) {
      var value = this[i];
      if (notFirst) {
        buffer.write(' | ');
      }
      buffer.write(value ?? '');
      notFirst = true;
    }
    return buffer.toString();
  }

  ReqIfAttributeValueXhtml appendXhtmlValue(String ref,
      [String ns = "reqif-xhtml"]) {
    xml.XmlBuilder builder = xml.XmlBuilder();
    builder.element(ReqIfAttributeValueXhtml.xmlName, nest: () {
      builder.text('\n');
      builder.element('DEFINITION', nest: () {
        builder.element('ATTRIBUTE-DEFINITION-XHTML-REF', nest: () {
          builder.text(ref);
        });
        builder.text('\n');
      });
      builder.text('\n');
      builder.element('THE-VALUE', nest: () {
        builder.element('$ns:div', nest: () {
          builder.element('$ns:br');
        });
      });
      builder.text('\n');
    });
    builder.text('\n');
    final fragment = builder.buildDocument();
    final babies = fragment.children;

    final targets = node.findElements(_xmlValues);
    if (targets.isEmpty) {
      throw ReqIfError('internal error: $node has no child $_xmlValues');
    }
    final toModify = targets.first.children;
    int lenBefore = toModify.length;
    for (final baby in babies) {
      toModify.add(baby.copy());
    }
    // add appends at end of list
    final newNode = toModify[lenBefore];
    assert(newNode is xml.XmlElement &&
        newNode.name.local == ReqIfAttributeValueXhtml.xmlName);
    children.add(ReqIfAttributeValueXhtml.parse(
        parent: this, element: newNode as xml.XmlElement, document: document));
    final newValue = children.last;
    children.sort((a, b) {
      a as ReqIfAttributeValue;
      b as ReqIfAttributeValue;
      return a.column.compareTo(b.column);
    });
    updateLastChange();
    return newValue as ReqIfAttributeValueXhtml;
  }

  ReqIfAttributeValueEnum appendEnumValue(String ref,
      [String ns = "reqif-xhtml"]) {
    var definition = document.resolveLink(ref);
    if (definition is! ReqIfAttributeEnumDefinition) {
      throw ReqIfError(
          'internal error: $ref does not resolve to an instance of ReqIfAttributeEnumDefinition');
    }
    List<String> initialValues = [];
    if (definition.hasDefaultValue) {
      if (definition.defaultValue is! ReqIfAttributeValueEnum) {
        throw ReqIfError(
            'internal error: Default value ${definition.defaultValue} has a wrong type');
      }
      final list = definition.defaultValue! as ReqIfAttributeValueEnum;
      for (var i = 0; i < list.length; ++i) {
        initialValues.add(list.id(i));
      }
    } else {
      initialValues.add(
          (definition.dataTypeDefinition as ReqIfDataTypeEnum).indexToId(0));
    }
    xml.XmlBuilder builder = xml.XmlBuilder();
    builder.element(ReqIfAttributeValueEnum.xmlName, nest: () {
      builder.text('\n');
      builder.element('DEFINITION', nest: () {
        builder.text('\n');
        builder.element('ATTRIBUTE-DEFINITION-ENUMERATION-REF', nest: () {
          builder.text(ref);
        });
        builder.text('\n');
      });
      builder.text('\n');
      builder.element('VALUES', nest: () {
        builder.text('\n');
        for (final val in initialValues) {
          builder.element('ENUM-VALUE-REF', nest: () {
            builder.text(val);
          });
          builder.text('\n');
        }
      });
      builder.text('\n');
    });
    builder.text('\n');
    final fragment = builder.buildDocument();
    final babies = fragment.children;

    final targets = node.findElements(_xmlValues);
    if (targets.isEmpty) {
      throw ReqIfError('internal error: $node has no child $_xmlValues');
    }
    final toModify = targets.first.children;
    int lenBefore = toModify.length;
    for (final baby in babies) {
      toModify.add(baby.copy());
    }
    // add appends at end of list
    final newNode = toModify[lenBefore];
    assert(newNode is xml.XmlElement &&
        newNode.name.local == ReqIfAttributeValueEnum.xmlName);
    children.add(ReqIfAttributeValueEnum.parse(
        parent: this, element: newNode as xml.XmlElement, document: document));
    final newValue = children.last;
    children.sort((a, b) {
      a as ReqIfAttributeValue;
      b as ReqIfAttributeValue;
      return a.column.compareTo(b.column);
    });
    updateLastChange();
    return newValue as ReqIfAttributeValueEnum;
  }
}
