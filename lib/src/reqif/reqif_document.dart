// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/document/document_service.dart';
import 'package:reqif_editor/src/reqif/reqif_io.dart';
import 'package:reqif_editor/src/reqif/reqif_spec_objects.dart';
import 'package:reqif_editor/src/reqif/reqif_spec_object_type.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_data_types.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';
import 'package:reqif_editor/src/reqif/reqif_specification.dart';
import 'package:xml/xml.dart' as xml;
import 'package:reqif_editor/src/reqif/reqif_header.dart';

class ReqIfDocument {
  late ReqIfHeader header;
  // read only to prevent users destroying the internal state
  // technically there should be only one of these elements
  final List<ReqIfDataTypes> _dataTypes;
  Iterable<ReqIfDataTypes> get dataTypes => _dataTypes;

  final List<ReqIfSpecificationObject> _specificationObjects;

  /// Returns all specification objects that are defined in the file.
  Iterable<ReqIfSpecificationObject> get specificationObjects =>
      _specificationObjects;

  final List<ReqIfSpecificationObjectType> _specificationObjectTypes;
  final List<ReqIfSpecification> _specifications;

  /// Returns the available columns per specification
  Iterable<ReqIfSpecificationObjectType> get specificationObjectTypes =>
      _specificationObjectTypes;

  /// Returns the available columns per specification
  Iterable<ReqIfSpecification> get specifications => _specifications;

  late xml.XmlDocument _document;

  final List<String> _xhtmlNamespacePrefixes = [];
  final List<String> _reqIfNamespacePrefixes = [];

  /// Namespace prefix for XHTML content.
  String get xhtmlNamespacePrefix => _xhtmlNamespacePrefixes.isNotEmpty
      ? _xhtmlNamespacePrefixes.first
      : "reqif-xhtml";

  /// Namespace prefix for XHTML content.
  String get reqIfNamespacePrefix =>
      _reqIfNamespacePrefixes.isNotEmpty ? _reqIfNamespacePrefixes.first : "";
  Iterable<String> get xhtmlNamespacePrefixes => _xhtmlNamespacePrefixes;
  Iterable<String> get reqIfNamespacePrefixes => _reqIfNamespacePrefixes;

  bool validateNameSpaces;

  ReqIfDocument({String title = "Requirements", this.validateNameSpaces = true})
      : _specificationObjectTypes = <ReqIfSpecificationObjectType>[],
        _specificationObjects = <ReqIfSpecificationObject>[],
        _dataTypes = <ReqIfDataTypes>[],
        _specifications = <ReqIfSpecification>[] {
    final builder = xml.XmlBuilder();
    builder.processing(
        "xml", 'version="1.0" encoding="UTF-8" standalone="yes"');
    builder.text("\n");
    builder.element('REQ-IF', nest: () {
      builder.attribute(
          "xmlns", "http://www.omg.org/spec/ReqIF/20110401/reqif.xsd");
      builder.attribute(
          "xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance");
      builder.attribute("xsi:schemaLocation",
          "http://www.omg.org/spec/ReqIF/20110401/reqif.xsd reqif.xsd");
      builder.attribute("xmlns:reqif-xhtml", "http://www.w3.org/1999/xhtml");
      builder.attribute("xmlns:rm-reqif", "http://www.ibm.com/rm/reqif");
      builder.attribute("xmlns:xhtml", "http://www.w3.org/1999/xhtml");
      builder.text("\n");

      builder.element('THE-HEADER', nest: () {
        builder.text("\n");
        builder.element('REQ-IF-HEADER', nest: () {
          builder.text("\n");
          builder.attribute("IDENTIFIER", "_1");
          builder.element("CREATION-TIME", nest: () {
            builder.text("2023-11-22T11:42:13+01:00");
          });
          builder.text("\n");
          builder.element("REQ-IF-TOOL-ID", nest: () {
            builder.text("Dart ReqIF File Version 1.0");
          });
          builder.text("\n");
          builder.element("REQ-IF-VERSION", nest: () {
            builder.text("1.0");
          });
          builder.text("\n");
          builder.element("SOURCE-TOOL-ID", nest: () {
            builder.text("com.github.reqif_editor.reqif_editor");
          });
          builder.text("\n");
          builder.element("TITLE", nest: () {
            builder.text(title);
          });
          builder.text("\n");
        });
        builder.text("\n");
      });
      builder.text("\n");

      builder.element('CORE-CONTENT', nest: () {
        builder.text("\n");
        builder.element('REQ-IF-CONTENT', nest: () {
          builder.text("\n");
          builder.element('DATATYPES', nest: () {
            builder.text("\n");
          });
          builder.text("\n");
          builder.element('SPEC-TYPES', nest: () {
            builder.text("\n");
          });
          builder.text("\n");

          builder.element('SPEC-OBJECTS', nest: () {
            builder.text("\n");
          });
          builder.text("\n");

          builder.element('SPEC-RELATIONS', nest: () {
            builder.text("\n");
          });
          builder.text("\n");

          builder.element('SPECIFICATIONS', nest: () {
            builder.text("\n");
          });
          builder.text("\n");

          builder.element('SPEC-RELATION-GROUPS', nest: () {
            builder.text("\n");
          });
          builder.text("\n");
        });
        builder.text("\n");
      });
      builder.text("\n");
    });
    builder.text("\n");
    _document = builder.buildDocument();
    final topLevel = _document.findElements('REQ-IF');
    _parseNamespaces(topLevel.first);
    _parseHeader(topLevel.first);
    _parseCoreContent(topLevel.first);
  }

  ReqIfDocument.parse(this._document, {this.validateNameSpaces = true})
      : _dataTypes = [],
        _specificationObjectTypes = [],
        _specifications = [],
        _specificationObjects = [] {
    final topLevel = _document.findElements('REQ-IF');
    if (topLevel.length != 1) {
      throw ReqIfError(
          "Failed to parse document! Only one REQ-IF node is allowed per document!");
    }

    _parseNamespaces(topLevel.first);
    _parseHeader(topLevel.first);
    _parseCoreContent(topLevel.first);
  }

  static const String xHtmlNamespaceUri = "http://www.w3.org/1999/xhtml";
  static const String reqIfNamespaceUri =
      "http://www.omg.org/spec/ReqIF/20110401/reqif.xsd";

  void _parseNamespaces(xml.XmlElement reqIf) {
    for (final attr in reqIf.attributes) {
      if (attr.value == xHtmlNamespaceUri) {
        _addNamespaceToList(_xhtmlNamespacePrefixes, attr.name);
      }
      if (attr.value == reqIfNamespaceUri) {
        _addNamespaceToList(_reqIfNamespacePrefixes, attr.name);
      }
    }
    _xhtmlNamespacePrefixes.sort((a, b) => a.length.compareTo(b.length));
    _reqIfNamespacePrefixes.sort((a, b) => a.length.compareTo(b.length));
    if (validateNameSpaces && _xhtmlNamespacePrefixes.isEmpty) {
      throw ReqIfError(
          'No namespace for xhtml found! Searched for $xHtmlNamespaceUri in REQ-IF node');
    }
    if (validateNameSpaces && _reqIfNamespacePrefixes.isEmpty) {
      throw ReqIfError(
          'No namespace for ReqIf found! Searched for $reqIfNamespaceUri in REQ-IF node');
    }
  }

  void _addNamespaceToList(List<String> l, xml.XmlName ns) {
    if (ns.prefix == "xmlns") {
      l.add(ns.local);
    } else {
      l.add('');
    }
  }

  void _parseHeader(xml.XmlElement reqIf) {
    final outerHeaders = reqIf.findElements('THE-HEADER');
    if (outerHeaders.length != 1) {
      throw ReqIfError(
          "Failed to parse document! Only one THE-HEADER node is allowed per document!");
    }
    final headers = outerHeaders.first.findElements('REQ-IF-HEADER');
    if (headers.length != 1) {
      throw ReqIfError(
          "Failed to parse document! Only one REQ-IF-HEADER node is allowed per document!");
    }
    header = ReqIfHeader.parse(headers.first);
  }

  void _parseCoreContent(xml.XmlElement reqIf) {
    final outerContent = reqIf.findElements('CORE-CONTENT');
    if (outerContent.length != 1) {
      throw ReqIfError(
          "Failed to parse document! Only one CORE-CONTENT node is allowed per document!");
    }
    final content = outerContent.first.findElements('REQ-IF-CONTENT');
    if (content.length != 1) {
      throw ReqIfError(
          "Failed to parse document! Only one REQ-IF-CONTENT node is allowed per document!");
    }
    _parseDataTypes(content.first);
    _parseSpecObjectTypes(content.first);
    _parseSpecObject(content.first);
    _parseSpecification(content.first);
  }

  void _parseDataTypes(xml.XmlElement reqIf) {
    for (final element in reqIf.findElements('DATATYPES')) {
      _dataTypes.add(ReqIfDataTypes.parse(element));
    }
  }

  /// parses the available columns per specification
  void _parseSpecObjectTypes(xml.XmlElement reqIf) {
    for (final specTypes in reqIf.findElements('SPEC-TYPES')) {
      for (final columns in specTypes.findElements('SPEC-OBJECT-TYPE')) {
        _specificationObjectTypes
            .add(ReqIfSpecificationObjectType.parse(columns, this));
      }
    }
  }

  /// parses all spec objects
  void _parseSpecObject(xml.XmlElement reqIf) {
    for (final specObjects in reqIf.findElements('SPEC-OBJECTS')) {
      for (final object in specObjects.findElements('SPEC-OBJECT')) {
        _specificationObjects.add(ReqIfSpecificationObject.parse(object, this));
      }
    }
  }

  void _parseSpecification(xml.XmlElement reqIf) {
    for (final specObjects in reqIf.findElements('SPECIFICATIONS')) {
      for (final object in specObjects.findElements('SPECIFICATION')) {
        _specifications.add(ReqIfSpecification.parse(object, this));
      }
    }
  }

  void updateDocumentId() {
    header.updateDocumentId();
  }

  void updateDocumentCreationTime() {
    header.updateDocumentCreationTime();
  }

  void write(String path) {
    writeXMLToFile(path, _document, DocumentService());
  }

  set toolId(String value) {
    header.toolId = value;
  }

  set sourceToolId(String value) {
    header.sourceToolId = value;
  }

  String get xmlString => convertXMLToString(_document);

  ReqIfElement? find(String id) {
    if (id.isEmpty) {
      return null;
    }
    if (header.identifier == id) {
      return header;
    }

    final type = _find(_dataTypes, id);
    if (type != null) {
      return type;
    }
    final specType = _find(_specificationObjectTypes, id);
    if (specType != null) {
      return specType;
    }
    final specObject = _find(_specificationObjects, id);
    if (specObject != null) {
      return specObject;
    }
    return null;
  }

  ReqIfElement? _find(List<ReqIfElement> container, String id) {
    for (final element in container) {
      final rv = _findInElement(element, id);
      if (rv != null) {
        return rv;
      }
    }
    return null;
  }

  ReqIfElement? _findInElement(ReqIfElement element, String id) {
    if (element is ReqIfElementWithId && element.identifier == id) {
      return element;
    }
    for (final child in element.children) {
      final rv = _findInElement(child, id);
      if (rv != null) {
        return rv;
      }
    }
    return null;
  }

  ReqIfElement resolveLink(String id) {
    final rv = find(id);
    if (rv == null) {
      throw ReqIfError("Failed to resolve identifier $id");
    }
    return rv;
  }
}
