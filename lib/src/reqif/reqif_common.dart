// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/reqif/reqif_error.dart';
import 'package:xml/xml.dart' as xml;
import 'package:uuid/uuid.dart';

var _uuid = const Uuid();

String createUUID() {
  return "_${_uuid.v4()}";
}

DateTime getTime() {
  return DateTime.now();
}

/// Return the current time in the following format:
/// yyyy-MM-ddTHH:mm:ss+OO:oo
String getTimeString() {
  return formatTimeString(getTime());
}

String formatTimeString(DateTime now) {
  final hourOffset = now.timeZoneOffset.inHours.toString().padLeft(2, '0');
  final minuteOffset =
      (now.timeZoneOffset.inMinutes % 60).toString().padLeft(2, '0');
  return "${now.toIso8601String().substring(0, 19)}+$hourOffset:$minuteOffset";
}

String getRequiredIdentifier(xml.XmlNode node) {
  return getRequiredAttribute(node, 'IDENTIFIER');
}

void setAttribute(xml.XmlNode node, String attribute, String? text) {
  node.setAttribute(attribute, text);
}

String getRequiredAttribute(xml.XmlNode node, String attribute) {
  final attr = node.getAttribute(attribute);
  if (attr == null || attr.isEmpty) {
    throw ReqIfError(
        'Failed to parse document! $attribute is required for $node');
  }
  return attr;
}

String? getOptionalAttribute(xml.XmlNode node, String attribute) {
  return node.getAttribute(attribute);
}

(String text, int count) getInnerTextOfChildElementsWithCount(
    xml.XmlNode node, String tag,
    [int maxCount = 1]) {
  String text = "";
  int count = 0;
  for (final element in node.findElements(tag)) {
    text += element.innerText;
    count += 1;
  }
  if (count < 1 || (maxCount < count && maxCount > 0)) {
    throw ReqIfError(
        'Failed to parse document! $node must have [1, $maxCount] child elements of type $tag');
  }
  return (text, count);
}

String getInnerTextOfChildElements(xml.XmlNode node, String tag,
    [int maxCount = 1]) {
  return getInnerTextOfChildElementsWithCount(node, tag, maxCount).$1;
}

String getInnerTextOfGrandChildElements(
    xml.XmlNode node, String childTag, String tag) {
  final children = node.findElements(childTag);
  if (children.length != 1) {
    throw ReqIfError(
        "Failed to parse document! Exactly one $childTag node is required!\n\nNode: $node");
  }
  return getInnerTextOfChildElementsWithCount(children.first, tag, 1).$1;
}

void setInnerTextOfChildElement(xml.XmlNode node, String tag, String text,
    [int maxCount = 1]) {
  setInnerTextOfChildElementOrCreateOne(node, tag, text,
      maxCount: maxCount, create: false);
}

void setInnerTextOfChildElementOrCreateOne(
    xml.XmlNode node, String tag, String text,
    {String? after, int maxCount = 1, bool create = true}) {
  int count = 0;
  for (final element in node.findElements(tag)) {
    element.innerText = text;
    count += 1;
  }
  if (count == 0 && create) {
    xml.XmlBuilder builder = xml.XmlBuilder();
    builder.element(tag, nest: () {
      builder.text(text);
    });
    builder.text('\n');
    final babies = builder.buildDocument().children;
    assert(babies.length == 2);
    int position = -1;
    if (after != null) {
      position = node.children.indexWhere(
          (itr) => itr is xml.XmlElement && itr.name.local == after);
    }
    position = position >= 0 ? position + 1 : 0;
    node.children.insert(position, babies[0].copy());
    node.children.insert(position, babies[1].copy());
    count = 1;
  }
  if (count < 1 || (maxCount < count && maxCount > 0)) {
    throw ReqIfError(
        'Internal Error while setting values! $node must have [1, $maxCount] child elements of type $tag');
  }
}

xml.XmlElement createGrandChildElementWithInnerText(
    xml.XmlNode node, String child, String grandchild, String innerText) {
  xml.XmlBuilder builder = xml.XmlBuilder();
  builder.element(grandchild, nest: () {
    builder.text(innerText);
  });
  builder.text('\n');
  final babies = builder.buildDocument().children;
  assert(babies.length == 2);
  final targets = node.findElements(child);
  if (targets.isEmpty) {
    throw ReqIfError('internal error: $node has no child $child');
  }
  final toModify = targets.first.children;
  toModify.add(babies[0].copy());
  toModify.add(babies[1].copy());
  return toModify[toModify.length - 2] as xml.XmlElement;
}

bool _isNewline(xml.XmlNode itr) =>
    itr is xml.XmlText && (itr.value == '\n' || itr.value == '\r\n');
bool _removeThis(xml.XmlNode itr, String tag) =>
    itr is xml.XmlElement && itr.name.local == tag;
bool _removeNext(xml.XmlNode? next, String tag,
        [int current = 0, int? target]) =>
    next is xml.XmlElement &&
    next.name.local == tag &&
    (target == null || current == target);

/// Removes child elements of [node] with the name [tag].
/// If there is a text element directly before that has only a newline
/// as content, then the preceding text is also removed.
///
/// If [position] is null, then all matching children are removed.
///
/// If [position] is not null, then only the child with the tag
/// at position [position] is removed.
void removeChildElements(xml.XmlNode node, String tag, {int? position}) {
  if (position == null) {
    node.children.removeWhere((itr) {
      final next = itr.nextSibling;
      bool removeThis = _removeThis(itr, tag);
      bool removeNext = _removeNext(next, tag);
      bool thisIsNewline = _isNewline(itr);
      return removeThis || (removeNext && thisIsNewline);
    });
    return;
  }
  int count = 0;
  node.children.removeWhere((itr) {
    final next = itr.nextSibling;
    bool removeThis = _removeThis(itr, tag);
    bool removeNext = _removeNext(next, tag, count, position);
    bool thisIsNewline = _isNewline(itr);
    int removeIndex = count;
    if (removeThis) {
      count += 1;
    }
    return (removeThis && removeIndex == position) ||
        (removeNext && thisIsNewline);
  });
}

(String? text, int count) getInnerTextOfOptionalChildElementsWithCount(
    xml.XmlNode node, String tag,
    [int maxCount = 1]) {
  String? text;
  int count = 0;
  for (final element in node.findElements(tag)) {
    text ??= "";
    text += element.innerText;
    count += 1;
  }
  if (maxCount < count && maxCount > 0) {
    throw ReqIfError(
        'Failed to parse document! $node must have [0, $maxCount] child elements of type $tag');
  }
  return (text, count);
}

String? getInnerTextOfOptionalChildElements(xml.XmlNode node, String tag,
    [int maxCount = 1]) {
  return getInnerTextOfOptionalChildElementsWithCount(node, tag, maxCount).$1;
}

enum ReqIfElementTypes {
  /// REQ-IF-HEADER
  header,

  /// DATATYPES
  /// container for all data types
  datatypes,

  /// DATATYPE-DEFINITION-STRING
  /// Describes raw text data types
  datatypeDefinitionString,

  /// DATATYPE-DEFINITION-ENUMERATION
  /// Describes formatted text data types
  datatypeDefinitionXhtml,

  /// DATATYPE-DEFINITION-ENUMERATION
  /// Describes an enum and all possible values
  datatypeDefinitionEnum,

  /// ENUM-VALUE
  /// Describes a value of an enum
  datatypeEnumValue,

  /// SPEC-OBJECT-TYPE
  /// Describes the columns of a specification.
  specificationObjectType,

  /// SPECIFICATION-TYPE
  /// Describes the attributes of a specification.
  specificationType,

  /// ATTRIBUTE-DEFINITION-***
  /// Describes the contents of a column of the specification.
  attributeDefinition,

  /// ATTRIBUTE-VALUE-XHTML
  /// contains one value and a reference to a column of the specification.
  attributeValueXhtml,

  /// ATTRIBUTE-VALUE-STRING
  /// contains one value and a reference to a column of the specification.
  attributeValueString,

  /// ATTRIBUTE-VALUE-ENUMERATION
  /// contains one value and a reference to a column of the specification.
  attributeValueEnumeration,

  /// SPEC-OBJECT
  /// Contains the actual specification data
  specificationObject,

  /// SPECIFICATION
  /// An ordered specification. Has hierarchy objects as children
  specification,

  /// SPEC-HIERARCHY
  /// Contains references to specificationObject and specificationHierarchy children.
  specificationHierarchy,
}

/// The line endings to use in the file when saving
enum LineEndings {
  /// Windows line endings using two bytes 0x0D 0A
  carriageReturnLinefeed,

  /// Linux line endings using one byte 0x0A
  linefeed
}

class ReqIfHierarchicalPosition {
  /// The positions to reach the current element.
  /// E.g. repeating children[position[i]] for every
  /// entry would reach the current element.
  List<int> position = [0];

  ReqIfHierarchicalPosition() : position = [0];
  ReqIfHierarchicalPosition.copy(ReqIfHierarchicalPosition other)
      : position = List.from(other.position);

  @override
  String toString() {
    final buffer = StringBuffer();
    bool notFirst = false;
    for (final val in position) {
      if (notFirst) {
        buffer.write(".");
      }
      buffer.write(val + 1);
      notFirst = true;
    }
    return buffer.toString();
  }
}

/// Represents a node in the document tree. The classes can usually be mapped
/// onto the classes described in the formal ReqIf specification.
class ReqIfElement {
  ReqIfElementTypes type;
  // ignore: prefer_final_fields
  late xml.XmlElement _node;

  ReqIfElement.parse(this._node, this.type) : children = <ReqIfElement>[];

  /// Gets the xml element representing this value.
  xml.XmlNode get node => _node;

  /// Gets the xml element representing this value.
  xml.XmlElement get element => _node;

  /// Returns the children of the node. Modifying this list outside of the
  /// provided API in ReqIfDocument will probably break your document. The
  /// ReqIfElement class and their child nodes are typically only views
  /// into the XML file, which represents the data model. Both the tree
  /// representation as well as the XML document have to be kept in sync.
  List<ReqIfElement> children;

  bool get hasChildren => children.isNotEmpty;

  void visit(
      {required void Function(ReqIfHierarchicalPosition, ReqIfElement) visitor,
      ReqIfHierarchicalPosition? position}) {
    position ??= ReqIfHierarchicalPosition();
    visitor(position, this);
    final next = ReqIfHierarchicalPosition.copy(position);
    next.position.add(0);
    for (final child in children) {
      child.visit(visitor: visitor, position: next);
      next.position.last += 1;
    }
  }
}

class ReqIfElementWithId extends ReqIfElement {
  /// Name of the xml attribute representing the identifier
  static const String xmlAttributeNameIdentifier = 'IDENTIFIER';

  late String _identifier;

  ReqIfElementWithId.parse(xml.XmlElement node, ReqIfElementTypes type)
      : super.parse(node, type) {
    _identifier = getRequiredAttribute(_node, xmlAttributeNameIdentifier);
  }

  set identifier(String text) {
    _identifier = text;
    setAttribute(_node, xmlAttributeNameIdentifier, text);
  }

  String get identifier => _identifier;

  /// Updates the identifier with a new random uuid.
  void setRandomIdentifier() {
    identifier = createUUID();
  }
}

class ReqIfElementWithIdTime extends ReqIfElementWithId {
  static const String _attributeNameLastChange = 'LAST-CHANGE';
  late DateTime _lastChange;

  ReqIfElementWithIdTime.parse(xml.XmlElement node, ReqIfElementTypes type)
      : super.parse(node, type) {
    _lastChange =
        DateTime.parse(getRequiredAttribute(_node, _attributeNameLastChange));
  }

  DateTime get lastChange => _lastChange;

  /// Sets the identifier.
  /// Also updates the last changed value.
  @override
  set identifier(String text) {
    _identifier = text;
    setAttribute(_node, ReqIfElementWithId.xmlAttributeNameIdentifier, text);
    updateLastChange();
  }

  /// Updates the identifier with a new random uuid.
  /// Also update the last changed value.
  @override
  void setRandomIdentifier() {
    super.setRandomIdentifier();
    updateLastChange();
  }

  set lastChange(DateTime now) {
    _lastChange = now;
    setAttribute(node, _attributeNameLastChange, formatTimeString(now));
  }

  void updateLastChange() {
    lastChange = getTime();
  }
}

mixin ReqIfNameAttribute on ReqIfElementWithIdTime {
  void _parseNameAttribute(xml.XmlNode node) {
    _name = getOptionalAttribute(_node, _attributeNameName);
  }

  static const String _attributeNameName = 'LONG-NAME';
  late String? _name;
  String? get name => _name;

  set name(String? text) {
    _name = text;
    setAttribute(_node, _attributeNameName, text);
    updateLastChange();
  }
}

mixin ReqIfDescriptionAttribute on ReqIfElementWithIdTime {
  void _parseDescriptionAttribute(xml.XmlNode node) {
    _description = getOptionalAttribute(_node, _attributeDescriptionName);
  }

  static const String _attributeDescriptionName = 'DESC';
  late String? _description;
  String? get description => _description;

  set description(String? text) {
    _description = text;
    setAttribute(_node, _attributeDescriptionName, text);
    updateLastChange();
  }
}

mixin ReqIfEditableAttribute on ReqIfElementWithIdTime {
  void parseEditableAttribute(xml.XmlNode node) {
    _isEditable =
        getOptionalAttribute(node, _xmlAttributeNameEditable) == "true";
  }

  bool _isEditable = false;

  static const String _xmlAttributeNameEditable = "IS-EDITABLE";

  bool get isEditable => _isEditable;
  set editable(bool v) {
    _isEditable = v;
    setAttribute(node, _xmlAttributeNameEditable, v.toString());
    updateLastChange();
  }
}

void buildChildObjects(
    {required xml.XmlElement element,
    required void Function(xml.XmlElement) builder,
    String? tag,
    String firstChildTag = "CHILDREN",
    int? maxOuterCount}) {
  int outerCount = 0;
  for (final children in element.findElements(firstChildTag)) {
    ++outerCount;
    if (tag != null) {
      for (final second in children.findElements(tag)) {
        builder(second);
      }
    } else {
      for (final second in children.childElements) {
        builder(second);
      }
    }
  }
  if (maxOuterCount != null && maxOuterCount < outerCount) {
    throw ReqIfError(
        'Only $maxOuterCount $firstChildTag child nodes are allowed! In element:\n\n$element');
  }
}

mixin ReqIfTableInternalAttribute on ReqIfElementWithIdTime {
  void parseTableInternalAttribute(xml.XmlNode node) {
    _isTableInternal = getOptionalAttribute(node, _xmlAttributeName) == "true";
  }

  bool _isTableInternal = false;

  static const String _xmlAttributeName = "IS-TABLE-INTERNAL";

  bool get isTableInternal => _isTableInternal;
  set editable(bool v) {
    _isTableInternal = v;
    setAttribute(node, _xmlAttributeName, v.toString());
    updateLastChange();
  }
}

class ReqIfIdentifiable extends ReqIfElementWithIdTime
    with ReqIfNameAttribute, ReqIfDescriptionAttribute {
  ReqIfIdentifiable.parse(xml.XmlElement node, ReqIfElementTypes type)
      : super.parse(node, type) {
    _parseNameAttribute(node);
    _parseDescriptionAttribute(node);
    // TODO alternative id
  }
}

typedef ReqIfElementWithIdNameTime = ReqIfIdentifiable;

class ReqIfElementWithIdNameTimeEditable extends ReqIfIdentifiable
    with ReqIfEditableAttribute {
  ReqIfElementWithIdNameTimeEditable.parse(
      xml.XmlElement node, ReqIfElementTypes type)
      : super.parse(node, type) {
    parseEditableAttribute(node);
  }
}

String getXmlDefinitionReferenceName(ReqIfElementTypes dataType) {
  switch (dataType) {
    case ReqIfElementTypes.attributeValueEnumeration:
      return "ATTRIBUTE-DEFINITION-ENUMERATION-REF";
    case ReqIfElementTypes.attributeValueString:
      return "ATTRIBUTE-DEFINITION-STRING-REF";
    case ReqIfElementTypes.attributeValueXhtml:
      return "ATTRIBUTE-DEFINITION-XHTML-REF";
    case ReqIfElementTypes.datatypeDefinitionXhtml:
      return "DATATYPE-DEFINITION-XHTML-REF";
    case ReqIfElementTypes.datatypeDefinitionEnum:
      return "DATATYPE-DEFINITION-ENUMERATION-REF";
    case ReqIfElementTypes.datatypeDefinitionString:
      return "DATATYPE-DEFINITION-STRING-REF";
    default:
      throw ReqIfError(
          "Internal error: getXmlDefinitionReferenceName called with $dataType");
  }
}

ReqIfElementTypes getXmlDefinitionDataType(ReqIfElementTypes dataType) {
  switch (dataType) {
    case ReqIfElementTypes.attributeValueEnumeration:
      return ReqIfElementTypes.datatypeDefinitionEnum;
    case ReqIfElementTypes.attributeValueString:
      return ReqIfElementTypes.datatypeDefinitionString;
    case ReqIfElementTypes.attributeValueXhtml:
      return ReqIfElementTypes.datatypeDefinitionXhtml;
    default:
      throw ReqIfError(
          "Internal error: getXmlDefinitionDataType called with $dataType");
  }
}

ReqIfElementTypes getDataTypeFromXmlTag(String element) {
  switch (element) {
    case "ATTRIBUTE-VALUE-ENUMERATION":
      return ReqIfElementTypes.attributeValueEnumeration;
    case "ATTRIBUTE-VALUE-STRING":
      return ReqIfElementTypes.attributeValueString;
    case "ATTRIBUTE-VALUE-XHTML":
      return ReqIfElementTypes.attributeValueXhtml;
    case "ATTRIBUTE-DEFINITION-ENUMERATION":
      return ReqIfElementTypes.datatypeDefinitionEnum;
    case "ATTRIBUTE-DEFINITION-STRING":
      return ReqIfElementTypes.datatypeDefinitionString;
    case "ATTRIBUTE-DEFINITION-XHTML":
      return ReqIfElementTypes.datatypeDefinitionXhtml;
    default:
      throw ReqIfError(
          "Internal error: getXmlDefinitionDataType called with $element");
  }
}
