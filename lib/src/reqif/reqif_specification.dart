// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';
import 'package:reqif_editor/src/reqif/reqif_spec_hierarchy.dart';
import 'package:reqif_editor/src/reqif/reqif_spec_object_type.dart';
import 'package:xml/xml.dart' as xml;

/// Holds the hierarchical data for a specification.
class ReqIfSpecification extends ReqIfIdentifiable {
  static const String xmlName = 'SPECIFICATION';
  static const String _xmlNameType = 'TYPE';
  static const String _xmlNameSpecificationTypeRef = 'SPECIFICATION-TYPE-REF';

  /// Constructs an instance of this type by parsing an existing ReqIF document.
  /// May throw an error if links cannot be resolved or if the the document
  /// is built not according to the spec.
  ///
  /// [element] must be of type SPEC-HIERARCHY.
  ///
  /// [document] is a reference to the parent document.
  ReqIfSpecification.parse(xml.XmlElement element, ReqIfDocument document)
      : super.parse(element, ReqIfElementTypes.specificationHierarchy) {
    _specificationObjectTypeReferenceId = getInnerTextOfGrandChildElements(
        element, _xmlNameType, _xmlNameSpecificationTypeRef);
    final link = document.resolveLink(_specificationObjectTypeReferenceId);
    if (link is! ReqIfSpecificationObjectType) {
      throw ReqIfError(
          'Failed to parse document: $_xmlNameSpecificationTypeRef $_specificationObjectTypeReferenceId does not resolve to a ${ReqIfSpecificationObjectType.xmlName}');
    }
    _specificationObjectType = link;
    buildChildObjects(
        element: element,
        tag: ReqIfSpecHierarchy.xmlName,
        builder: (element) =>
            children.add(ReqIfSpecHierarchy.parse(element, document)));
  }

  late String _specificationObjectTypeReferenceId;
  late ReqIfSpecificationObjectType _specificationObjectType;

  /// Returns the link id to the column definition object.
  String get specificationObjectTypeReferenceId =>
      _specificationObjectTypeReferenceId;

  /// Returns the resolved link to the column definition object.
  ReqIfSpecificationObjectType get specificationObjectType =>
      _specificationObjectType;
}
