// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/reqif/reqif_attribute_definitions.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_data_types.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';
import 'package:xml/xml.dart' as xml;

class ReqIfAttributeValue extends ReqIfElement {
  static const String _xmlDefinitionName = "DEFINITION";
  ReqIfElementWithIdNameTime parent;
  ReqIfDocument document;

  /// [node] must be ATTRIBUTE-VALUE-XXX
  ///
  /// children:
  /// ATTRIBUTE-VALUE-XXX
  ///   DEFINITION
  ///     ATTRIBUTE-DEFINITION-XXX-REF
  ///   VALUES or THE-VALUE
  ReqIfAttributeValue.parse(
      {required this.parent,
      required xml.XmlElement element,
      required this.document,
      ReqIfElement? link})
      : _dataType =
            getXmlDefinitionDataType(getDataTypeFromXmlTag(element.name.local)),
        super.parse(element, getDataTypeFromXmlTag(element.name.local)) {
    final definitions = node.findElements(_xmlDefinitionName);
    if (definitions.length != 1) {
      throw ReqIfError(
          "Failed to parse document! Exactly one DEFINITION node is required!\n\n$node");
    }
    _definitionReferenceId = getInnerTextOfChildElements(
        definitions.first,
        getXmlDefinitionReferenceName(
            getDataTypeFromXmlTag(element.name.local)));
    link ??= document.resolveLink(_definitionReferenceId);
    if (link is! ReqIfAttributeDefinition ||
        link.type != ReqIfElementTypes.attributeDefinition ||
        link.dataTypeDefinition.type != _dataType) {
      throw ReqIfError(
          "Failed to parse document! Definition reference $_definitionReferenceId was not resolved correctly!\n\n$node");
    }
    _definition = link;
  }

  final ReqIfElementTypes _dataType;
  ReqIfElementTypes get dataType => _dataType;
  late String _definitionReferenceId;
  late ReqIfAttributeDefinition _definition;

  /// Id of the definition of the linked attribute definition
  String get definitionId => _definitionReferenceId;
  ReqIfAttributeDefinition get definition => _definition;

  bool get isEditable => definition.isEditable;

  int get column => _definition.index;

  int get embeddedObjectCount => 0;

  String toStringWithNewlines() {
    return toString();
  }
}

class ReqIfAttributeValueSimple extends ReqIfAttributeValue {
  static const String xmlNameValue = 'THE-VALUE';

  ReqIfAttributeValueSimple.parse(
      {required super.parent,
      required xml.XmlElement element,
      required super.document,
      super.link})
      : super.parse(element: element) {
    _valueString = getRequiredAttribute(element, xmlNameValue);
  }

  late String _valueString;
  String get valueString => _valueString;
  set valueString(String v) {
    _valueString = v;
    setAttribute(node, xmlNameValue, v);
    parent.updateLastChange();
  }

  @override
  String toString() {
    return valueString;
  }
}

class ReqIfAttributeValueString extends ReqIfAttributeValueSimple {
  static const String xmlName = 'ATTRIBUTE-VALUE-STRING';

  ReqIfAttributeValueString.parse(
      {required super.parent,
      required super.element,
      required super.document,
      super.link})
      : super.parse();
}

class ReqIfAttributeValueInteger extends ReqIfAttributeValueSimple {
  static const String xmlName = 'ATTRIBUTE-VALUE-INTEGER';

  ReqIfAttributeValueInteger.parse(
      {required super.parent,
      required super.element,
      required super.document,
      super.link})
      : super.parse();
}

class ReqIfAttributeValueBool extends ReqIfAttributeValueSimple {
  static const String xmlName = 'ATTRIBUTE-VALUE-BOOLEAN';

  ReqIfAttributeValueBool.parse(
      {required super.parent,
      required super.element,
      required super.document,
      super.link})
      : super.parse();
}

class ReqIfAttributeValueReal extends ReqIfAttributeValueSimple {
  static const String xmlName = 'ATTRIBUTE-VALUE-REAL';

  ReqIfAttributeValueReal.parse(
      {required super.parent,
      required super.element,
      required super.document,
      super.link})
      : super.parse();
}

class ReqIfAttributeValueDate extends ReqIfAttributeValueSimple {
  static const String xmlName = 'ATTRIBUTE-VALUE-DATE';

  ReqIfAttributeValueDate.parse(
      {required super.parent,
      required super.element,
      required super.document,
      super.link})
      : super.parse();
}

class ReqIfAttributeValueEnum extends ReqIfAttributeValue {
  static const String xmlName = 'ATTRIBUTE-VALUE-ENUMERATION';
  ReqIfAttributeValueEnum.parse(
      {required super.parent,
      required xml.XmlElement element,
      required super.document,
      super.link})
      : _values = [],
        super.parse(element: element) {
    buildChildObjects(
        element: element,
        firstChildTag: 'VALUES',
        tag: 'ENUM-VALUE-REF',
        maxOuterCount: 1,
        builder: (inner) {
          _values.add((enumDefinition.idToValue(inner.innerText), inner));
        });
    updateCache();
  }

  final List<(String, xml.XmlElement)> _values;

  int get length => _values.length;
  late String _cachedString;

  void updateCache() => _cachedString = _toString();

  /// Gets the value of the multi-valued enum field at index [i]
  /// as either long name (if defined) or as number key.
  ///
  /// [i] must be smaller than length.
  String value(int i) {
    return _values[i].$1;
  }

  /// Gets the referenced id of the multi-valued enum field at index [i]
  /// as string.
  ///
  /// [i] must be smaller than length.
  String id(int i) {
    return enumDefinition.valueToId(value(i));
  }

  /// Sets the value of the multi-valued enum field at index [i]
  /// to [value]. [value] must be a valid entry in the enum and [i]<length,
  /// otherwise an exception is thrown.
  void setValue(int i, String value) {
    final id = enumDefinition.valueToId(value);
    _values[i] = (value, _values[i].$2);
    _values[i].$2.innerText = id;
    updateCache();
    parent.updateLastChange();
  }

  ReqIfAttributeEnumDefinition get columnDefinition =>
      (definition as ReqIfAttributeEnumDefinition);
  ReqIfDataTypeEnum get enumDefinition =>
      columnDefinition.dataTypeDefinition as ReqIfDataTypeEnum;
  bool get isMultiValued => columnDefinition.isMultiValued;

  Iterable<String> get validValues => enumDefinition.validValues;

  /// Adds the [value] at the end of the multi-valued enum field.
  /// [value] must be a valid entry in the enum, otherwise
  /// an exception is thrown.
  void addValue(String value) {
    final id = enumDefinition.valueToId(value);
    final newNode = createGrandChildElementWithInnerText(
        node, 'VALUES', 'ENUM-VALUE-REF', id);
    _values.add((value, newNode));
    updateCache();
    parent.updateLastChange();
  }

  /// Removes the value at [index].
  void removeValue(int index) {
    final removed = _values.removeAt(index);
    final value = removed.$2.parent;
    if (value != null) {
      removeChildElements(value, 'ENUM-VALUE-REF', position: index);
    } else {
      throw ReqIfError('Internal error: ${removed.$2} is an orphan');
    }
    updateCache();
    parent.updateLastChange();
  }

  String _toString() {
    final buffer = StringBuffer();
    buffer.write("[");
    bool first = true;
    for (final val in _values) {
      if (!first) {
        buffer.write(", ");
      }
      buffer.write(val.$1);
      first = false;
    }
    buffer.write("]");
    return buffer.toString();
  }

  @override
  String toString() => _cachedString;
}

class ReqIfAttributeValueXhtml extends ReqIfAttributeValue {
  static const String xmlName = "ATTRIBUTE-VALUE-XHTML";
  static const String _xmlValueName = "THE-VALUE";
  static const String _xmlObjectName = "object";
  ReqIfAttributeValueXhtml.parse(
      {required super.parent,
      required xml.XmlElement element,
      required super.document,
      super.link})
      : super.parse(element: element) {
    final values = element.findAllElements(_xmlValueName);
    if (values.length != 1) {
      throw ReqIfError(
          "Failed to parse document: $xmlName must have one $_xmlValueName child!\n\n$node");
    }
    if (values.first.childElements.length != 1) {
      throw ReqIfError(
          "Failed to parse document: $xmlName - $_xmlValueName must have exactly one child, either <xhtml:div> or <xhtml:p>!\n\n$node");
    }
    _theValue = values.first.childElements.first;
    updateCache();
  }

  late xml.XmlElement _theValue;
  String get namespacePrefixForValue =>
      _theValue.name.prefix ?? document.xhtmlNamespacePrefix;

  xml.XmlElement get value => _theValue.copy();

  set value(xml.XmlElement newValue) {
    if (newValue.name.local != "p" && newValue.name.local != "div") {
      throw ReqIfError(
          "The value of a XHTML node must be a <div> or <p> element!");
    }
    if (document.validateNameSpaces &&
        newValue.name.prefix != namespacePrefixForValue &&
        !document.xhtmlNamespacePrefixes
            .any((element) => element == newValue.name.prefix)) {
      throw ReqIfError(
          "The value of a XHTML node must be in the XHTML namespace of the document!");
    }
    final copy = newValue.copy();
    _theValue.replace(copy);
    _theValue = copy;
    updateCache();
    parent.updateLastChange();
  }

  late String _cachedString;
  late String _cachedStringWithNewlines;

  void updateCache() {
    _cachedString = _toString();
    _cachedStringWithNewlines = _toStringWithNewlines();
  }

  /// Returns the unformatted text of the node.
  @override
  String toString() => _cachedString;

  @override
  String toStringWithNewlines() => _cachedStringWithNewlines;

  /// Counts the embedded objects in the formatted text.
  /// Each object must either be image/png or have an alternative image/png image.
  /// So we can just count image/png objects and get the correct number if the
  /// input conforms to the reqif spec.
  @override
  int get embeddedObjectCount {
    int countPng = 0;
    for (final child in node.findAllElements(_xmlValueName, namespace: "*")) {
      for (final object
          in child.findAllElements(_xmlObjectName, namespace: "*")) {
        if (object.getAttribute('type') == "image/png") {
          countPng += 1;
        }
      }
    }
    return countPng;
  }

  /// Returns the unformatted text of the node.
  String _toString() {
    final buffer = StringBuffer();
    for (final child in node.findAllElements(_xmlValueName)) {
      buffer.write(child.innerText);
    }
    return buffer.toString();
  }

  String _toStringWithNewlines() {
    final buffer = StringBuffer();
    for (final child in node.findAllElements(_xmlValueName)) {
      for (final xhtml in child.descendants) {
        if (xhtml is xml.XmlElement &&
            (xhtml.name.local == "br" || xhtml.name.local == "li")) {
          buffer.write('\n');
        }
        if (xhtml.value != null) {
          buffer.write(xhtml.value);
        }
      }
    }
    return buffer.toString();
  }
}
