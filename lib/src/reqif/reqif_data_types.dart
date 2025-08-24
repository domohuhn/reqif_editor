// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';
import 'package:xml/xml.dart' as xml;

/// This class holds all defined datatypes in the reqif document
class ReqIfDataTypes extends ReqIfElement {
  static const String xmlName = 'DATATYPES';

  /// [node] must be DATATYPES
  ReqIfDataTypes.parse(xml.XmlElement node)
      : super.parse(node, ReqIfElementTypes.datatypes) {
    if (node.name.local != xmlName) {
      throw ReqIfError(
          'Internal error: wrong node given to ReqIfDataTypes.parse\n\n$node');
    }
    for (var element in node.childElements) {
      switch (element.name.local) {
        case ReqIfDataTypeString.xmlName:
          children.add(ReqIfDataTypeString.parse(element));
        case ReqIfDataTypeXhtml.xmlName:
          children.add(ReqIfDataTypeXhtml.parse(element));
        case ReqIfDataTypeEnum.xmlName:
          children.add(ReqIfDataTypeEnum.parse(element));
        case ReqIfDataTypeInt.xmlName:
          children.add(ReqIfDataTypeInt.parse(element));
        case ReqIfDataTypeReal.xmlName:
          children.add(ReqIfDataTypeReal.parse(element));
        case ReqIfDataTypeDate.xmlName:
          children.add(ReqIfDataTypeDate.parse(element));
        case ReqIfDataTypeBool.xmlName:
          children.add(ReqIfDataTypeBool.parse(element));
      }
    }
  }

  List<ReqIfElement> get types => children;
}

class ReqIfDataTypeString extends ReqIfIdentifiable {
  static const String xmlName = 'DATATYPE-DEFINITION-STRING';

  /// [node] must be DATATYPE-DEFINITION-STRING
  ReqIfDataTypeString.parse(xml.XmlElement node)
      : super.parse(node, ReqIfElementTypes.datatypeDefinitionString) {
    if (node.name.local != xmlName) {
      throw ReqIfError(
          'Internal error: wrong node given to ReqIfDataTypeString.parse\n\n$node');
    }
    _maxLength =
        int.parse(getRequiredAttribute(node, _xmlAttributeNameMaxLength));
  }

  int _maxLength = 1024;
  static const String _xmlAttributeNameMaxLength = "MAX-LENGTH";

  int get maxLength => _maxLength;
  set maxLength(int v) {
    _maxLength = v;
    setAttribute(node, _xmlAttributeNameMaxLength, v.toString());
    updateLastChange();
  }
}

mixin ReqIfMinMaxInt {
  static const String _xmlMin = 'MIN';
  static const String _xmlMax = 'MAX';

  void parseMinMax(xml.XmlElement el) {
    _minimum = int.parse(getRequiredAttribute(el, _xmlMin));
    _maximum = int.parse(getRequiredAttribute(el, _xmlMax));
  }

  late int _minimum;
  late int _maximum;
  int get minimum => _minimum;
  int get maximum => _maximum;
}

mixin ReqIfMinMaxReal {
  static const String _xmlMin = 'MIN';
  static const String _xmlMax = 'MAX';

  void parseMinMax(xml.XmlElement el) {
    _minimum = double.parse(getRequiredAttribute(el, _xmlMin));
    _maximum = double.parse(getRequiredAttribute(el, _xmlMax));
  }

  late double _minimum;
  late double _maximum;
  double get minimum => _minimum;
  double get maximum => _maximum;
}

class ReqIfDataTypeInt extends ReqIfIdentifiable with ReqIfMinMaxInt {
  static const String xmlName = 'DATATYPE-DEFINITION-INTEGER';

  /// [node] must be DATATYPE-DEFINITION-INTEGER
  ReqIfDataTypeInt.parse(xml.XmlElement node)
      : super.parse(node, ReqIfElementTypes.datatypeDefinitionInteger) {
    if (node.name.local != xmlName) {
      throw ReqIfError(
          'Internal error: wrong node given to ReqIfDataTypeInt.parse\n\n$node');
    }
    parseMinMax(node);
  }
}

class ReqIfDataTypeReal extends ReqIfIdentifiable with ReqIfMinMaxReal {
  static const String xmlName = 'DATATYPE-DEFINITION-REAL';
  static const String _xmlAccuracy = 'ACCURACY';

  /// [node] must be DATATYPE-DEFINITION-REAL
  ReqIfDataTypeReal.parse(xml.XmlElement node)
      : super.parse(node, ReqIfElementTypes.datatypeDefinitionReal) {
    if (node.name.local != xmlName) {
      throw ReqIfError(
          'Internal error: wrong node given to ReqIfDataTypeReal.parse\n\n$node');
    }
    parseMinMax(node);
    _accuracy = int.parse(getRequiredAttribute(node, _xmlAccuracy));
  }

  int _accuracy = 2;
  int get accuracy => _accuracy;
}

class ReqIfDataTypeBool extends ReqIfIdentifiable {
  static const String xmlName = 'DATATYPE-DEFINITION-BOOLEAN';

  /// [node] must be DATATYPE-DEFINITION-BOOLEAN
  ReqIfDataTypeBool.parse(xml.XmlElement node)
      : super.parse(node, ReqIfElementTypes.datatypeDefinitionBoolean) {
    if (node.name.local != xmlName) {
      throw ReqIfError(
          'Internal error: wrong node given to ReqIfDataTypeBool.parse\n\n$node');
    }
  }
}

class ReqIfDataTypeDate extends ReqIfIdentifiable {
  static const String xmlName = 'DATATYPE-DEFINITION-DATE';

  /// [node] must be DATATYPE-DEFINITION-DATE
  ReqIfDataTypeDate.parse(xml.XmlElement node)
      : super.parse(node, ReqIfElementTypes.datatypeDefinitionDate) {
    if (node.name.local != xmlName) {
      throw ReqIfError(
          'Internal error: wrong node given to ReqIfDataTypeDate.parse\n\n$node');
    }
  }
}

class ReqIfDataTypeXhtml extends ReqIfIdentifiable {
  static const String xmlName = 'DATATYPE-DEFINITION-XHTML';

  /// [node] must be DATATYPE-DEFINITION-XHTML
  ReqIfDataTypeXhtml.parse(xml.XmlElement node)
      : super.parse(node, ReqIfElementTypes.datatypeDefinitionXhtml) {
    if (node.name.local != xmlName) {
      throw ReqIfError(
          'Internal error: wrong node given to ReqIfDataTypeXhtml.parse\n\n$node');
    }
  }
}

class ReqIfDataTypeEnum extends ReqIfIdentifiable {
  static const String xmlName = 'DATATYPE-DEFINITION-ENUMERATION';

  /// [node] must be DATATYPE-DEFINITION-ENUMERATION
  ///
  /// it must have children:
  /// DATATYPE-DEFINITION-ENUMERATION
  ///   SPECIFIED-VALUES
  ///     ENUM-VALUE
  ReqIfDataTypeEnum.parse(xml.XmlElement node)
      : _validValues = [],
        super.parse(node, ReqIfElementTypes.datatypeDefinitionEnum) {
    if (node.name.local != xmlName) {
      throw ReqIfError(
          'Internal error: wrong node given to ReqIfDataTypeEnum.parse\n\n$node');
    }
    final values = node.findElements('SPECIFIED-VALUES');
    if (values.length != 1) {
      throw ReqIfError(
          "Failed to parse document $node!\n\nOnly one SPECIFIED-VALUES node is allowed per DATATYPE-DEFINITION-ENUMERATION!");
    }

    for (var element in values.first.findElements('ENUM-VALUE')) {
      children.add(ReqIfDataTypeEnumValue.parse(element));
    }
    children.sort((a, b) {
      final lhs = a as ReqIfDataTypeEnumValue;
      final rhs = b as ReqIfDataTypeEnumValue;
      return lhs.key.compareTo(rhs.key);
    });
    _validValues.addAll(children.map((e) => e.toString()));
  }

  final List<String> _validValues;
  Iterable<String> get validValues => _validValues;

  int get values => children.length;
  String value(int i) {
    if (i > children.length) {
      throw ReqIfError(
          "Internal error!\n\nEnum only has ${children.length} but $i was requested");
    }
    String? name = (children[i] as ReqIfDataTypeEnumValue).name;
    if (name == null) {
      return (children[i] as ReqIfDataTypeEnumValue).key.toString();
    }
    return name;
  }

  String indexToId(int i) {
    if (i > children.length) {
      throw ReqIfError(
          "Internal error!\n\nEnum only has ${children.length} but $i was requested");
    }
    return (children[i] as ReqIfElementWithId).identifier;
  }

  String valueToId(String value) {
    for (final child in children) {
      child as ReqIfDataTypeEnumValue;
      if (child.name == value) {
        return child.identifier;
      }
    }
    for (final child in children) {
      child as ReqIfDataTypeEnumValue;
      if (child.key.toString() == value) {
        return child.identifier;
      }
    }
    throw ReqIfError('Invalid enum value: $value');
  }

  String idToValue(String identifier) {
    for (final child in children) {
      child as ReqIfDataTypeEnumValue;
      if (child.identifier == identifier) {
        return child.name ?? child.key.toString();
      }
    }
    throw ReqIfError('Invalid enum value identifier: $identifier');
  }
}

class ReqIfDataTypeEnumValue extends ReqIfIdentifiable {
  static const String xmlName = 'ENUM-VALUE';

  late xml.XmlNode _embeddedValue;

  /// [node] must be ENUM-VALUE
  ///
  /// it must have children:
  /// ENUM-VALUE
  ///   PROPERTIES
  ///     EMBEDDED-VALUE
  ///
  ReqIfDataTypeEnumValue.parse(xml.XmlElement node)
      : super.parse(node, ReqIfElementTypes.datatypeEnumValue) {
    if (node.name.local != xmlName) {
      throw ReqIfError(
          'Internal error: wrong node given to ReqIfDataTypeEnumValue.parse\n\n$node');
    }
    final props = node.findElements('PROPERTIES');
    if (props.length != 1) {
      throw ReqIfError(
          "Failed to parse document in $node!\n\nOnly one PROPERTIES node is allowed per ENUM-VALUE!");
    }
    final values = props.first.findElements('EMBEDDED-VALUE');
    if (values.length != 1) {
      throw ReqIfError(
          "Failed to parse document $node!\n\nOnly one EMBEDDED-VALUE node is allowed per PROPERTIES!");
    }
    _embeddedValue = values.first;
    _key =
        int.parse(getRequiredAttribute(_embeddedValue, _xmlAttributeNameKey));
    _otherContent =
        getRequiredAttribute(_embeddedValue, _xmlAttributeNameOtherContent);
  }

  int _key = 1024;
  String _otherContent = "-1";
  static const String _xmlAttributeNameKey = "KEY";
  static const String _xmlAttributeNameOtherContent = "OTHER-CONTENT";

  int get key => _key;
  set key(int v) {
    _key = v;
    setAttribute(_embeddedValue, _xmlAttributeNameKey, v.toString());
    updateLastChange();
  }

  String get otherContent => _otherContent;
  set otherContent(String v) {
    _otherContent = v;
    setAttribute(_embeddedValue, _xmlAttributeNameOtherContent, v);
    updateLastChange();
  }

  @override
  String toString() {
    final rv = name;
    if (rv != null) {
      return rv;
    }
    return key.toString();
  }
}
