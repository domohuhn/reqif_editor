// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/reqif/reqif_attribute_default_value.dart';
import 'package:reqif_editor/src/reqif/reqif_attribute_values.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';
import 'package:xml/xml.dart' as xml;

class ReqIfAttributeDefinition extends ReqIfElementWithIdNameTimeEditable {
  /// [node] must be ATTRIBUTE-DEFINITION-XXX
  ///
  /// children:
  ///   ATTRIBUTE-DEFINITION-XXX
  ///     TYPE
  ///       DATATYPE-DEFINITION-XXX-REF
  ///     DEFAULT-VALUE
  ///
  ReqIfAttributeDefinition.parse(
      xml.XmlElement element, ReqIfDocument document, this.index,
      [ReqIfElementTypes nodeType = ReqIfElementTypes.attributeDefinition])
      : _dataType = getDataTypeFromXmlTag(element.name.local),
        super.parse(element, ReqIfElementTypes.attributeDefinition) {
    String xmlDefinition = getXmlDefinitionReferenceName(_dataType);
    final outerContent = node.findElements('TYPE');
    if (outerContent.length != 1) {
      throw ReqIfError(
          "Failed to parse document! Only one TYPE node is allowed per node!\n\n$node");
    }
    _referencedDataTypeId =
        getInnerTextOfChildElements(outerContent.first, xmlDefinition);
    final link = document.find(_referencedDataTypeId);
    if (link == null || link.type != _dataType) {
      throw ReqIfError(
          "Failed to parse document! Referenced data type $_referencedDataTypeId does not exist!\n\n$node");
    }
    _dataTypeDefinition = link as ReqIfElementWithIdNameTime;
    if (name == null) {
      throw ReqIfError(
          "Failed to parse document! LONG-NAME is mandatory for all AttributeDefinitions!\n\n$node");
    }

    final defValue = node.findElements(ReqIfAttributeDefaultValue.xmlName);
    if (defValue.length > 1) {
      throw ReqIfError(
          "Failed to parse document! A maximum of one ${ReqIfAttributeDefaultValue.xmlName} is allowed per node!\n\n$node");
    }
    for (final element in defValue) {
      _defaultValue = ReqIfAttributeDefaultValue.parse(element, document, this);
    }
  }
  final ReqIfElementTypes _dataType;
  ReqIfElementTypes get dataType => _dataType;

  late String _referencedDataTypeId;

  /// Returns the identifier of the referenced data type.
  String get referencedDataTypeId => _referencedDataTypeId;

  late ReqIfElementWithIdNameTime _dataTypeDefinition;

  /// The referenced data type if it could be resolved.
  ReqIfElementWithIdNameTime get dataTypeDefinition => _dataTypeDefinition;

  int index = 0;

  bool get isText =>
      dataType == ReqIfElementTypes.datatypeDefinitionXhtml ||
      dataType == ReqIfElementTypes.datatypeDefinitionString;

  ReqIfAttributeDefaultValue? _defaultValue;

  bool get hasDefaultValue => _defaultValue != null;

  ReqIfAttributeValue? get defaultValue =>
      hasDefaultValue ? _defaultValue!.value : null;
}

class ReqIfAttributeEnumDefinition extends ReqIfAttributeDefinition {
  static const String xmlName = "ATTRIBUTE-DEFINITION-ENUMERATION";
  ReqIfAttributeEnumDefinition.parse(
      xml.XmlElement element, ReqIfDocument document, index)
      : super.parse(
            element, document, index, ReqIfElementTypes.attributeDefinition) {
    _isMultiValued =
        getRequiredAttribute(node, _xmlAttributeNameMultiValue) == "true";
  }
  bool _isMultiValued = false;

  static const String _xmlAttributeNameMultiValue = "MULTI-VALUED";

  bool get isMultiValued => _isMultiValued;
  set isMultiValued(bool v) {
    _isMultiValued = v;
    setAttribute(node, _xmlAttributeNameMultiValue, v.toString());
    updateLastChange();
  }
}
