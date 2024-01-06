// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';
import 'package:reqif_editor/src/reqif/reqif_spec_objects.dart';
import 'package:xml/xml.dart' as xml;

/// Holds the hierarchical data for a specification.
class ReqIfSpecHierarchy extends ReqIfIdentifiable
    with ReqIfEditableAttribute, ReqIfTableInternalAttribute {
  static const String xmlName = 'SPEC-HIERARCHY';
  static const String _xmlNameObject = 'OBJECT';
  static const String _xmlNameSpecObjectRef = 'SPEC-OBJECT-REF';

  /// Constructs an instance of this type by parsing an existing ReqIF document.
  /// May throw an error if links cannot be resolved or if the the document
  /// is built not according to the spec.
  ///
  /// [element] must be of type SPEC-HIERARCHY.
  ///
  /// [document] is a reference to the parent document.
  ReqIfSpecHierarchy.parse(xml.XmlElement element, ReqIfDocument document)
      : super.parse(element, ReqIfElementTypes.specificationHierarchy) {
    _specificationObjectReferenceId = getInnerTextOfGrandChildElements(
        element, _xmlNameObject, _xmlNameSpecObjectRef);
    final link = document.resolveLink(_specificationObjectReferenceId);
    if (link is! ReqIfSpecificationObject) {
      throw ReqIfError(
          'Failed to parse document: $_xmlNameSpecObjectRef $_specificationObjectReferenceId does not resolve to a ${ReqIfSpecificationObject.xmlName}');
    }
    _specificationObject = link;
    parseEditableAttribute(element);
    parseTableInternalAttribute(element);

    buildChildObjects(
        element: element,
        tag: xmlName,
        builder: (element) =>
            children.add(ReqIfSpecHierarchy.parse(element, document)));
  }
  late String _specificationObjectReferenceId;
  late ReqIfSpecificationObject _specificationObject;

  /// Returns the link id to an specification object.
  String get specificationObjectId => _specificationObjectReferenceId;

  /// Returns the resolved link to an specification object.
  ReqIfSpecificationObject get specificationObject => _specificationObject;
}
