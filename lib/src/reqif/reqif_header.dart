// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';
import 'package:xml/xml.dart' as xml;

/// This class holds metadata relevant to the Exchange Document content.
/// Refers to 9.2.3 in specification.
///
/// Must be the first child of the root node.
class ReqIfHeader extends ReqIfElementWithId {
  String? _comment;
  late String _reqIfVersion;
  late String _title;
  String? _repositoryId;
  late String _toolId;
  late String _sourceToolId;
  late DateTime _creationTime;

  String get reqIfVersion => _reqIfVersion;
  String get title => _title;
  String? get comment => _comment;
  String? get repositoryId => _repositoryId;
  String get toolId => _toolId;
  String get sourceToolId => _sourceToolId;
  DateTime get creationTime => _creationTime;

  static const String _elementNameToolId = 'REQ-IF-TOOL-ID';
  static const String _elementNameSourceToolId = 'SOURCE-TOOL-ID';
  static const String _elementNameTitle = 'TITLE';
  static const String _elementNameCreationTime = 'CREATION-TIME';
  static const String _elementNameComment = 'COMMENT';
  static const String _elementNameRepositoryId = 'REPOSITORY-ID';
  static const String xmlName = 'REQ-IF-HEADER';

  ReqIfHeader.parse(xml.XmlElement node)
      : super.parse(node, ReqIfElementTypes.header) {
    if (node.name.local != xmlName) {
      throw ReqIfError(
          'Internal error: wrong node given to ReqIfHeader.parse\n\n$node');
    }
    _reqIfVersion = getInnerTextOfChildElements(node, 'REQ-IF-VERSION');

    _toolId = getInnerTextOfChildElements(node, _elementNameToolId);
    _sourceToolId = getInnerTextOfChildElements(node, _elementNameSourceToolId);

    _title = getInnerTextOfChildElements(node, _elementNameTitle);

    final timeStr = getInnerTextOfChildElements(node, _elementNameCreationTime);
    _creationTime = DateTime.parse(timeStr);

    _comment = getInnerTextOfOptionalChildElements(node, _elementNameComment);

    _repositoryId =
        getInnerTextOfOptionalChildElements(node, _elementNameRepositoryId);

    if (_reqIfVersion != "1.0") {
      throw ReqIfError(
          'Failed to parse document! REQ-IF-VERSION must be 1.0! Got: $_reqIfVersion');
    }
  }

  set toolId(String text) {
    _toolId = text;
    setInnerTextOfChildElement(node, _elementNameToolId, text);
  }

  set sourceToolId(String text) {
    _sourceToolId = text;
    setInnerTextOfChildElement(node, _elementNameSourceToolId, text);
  }

  set title(String text) {
    _title = text;
    setInnerTextOfChildElement(node, _elementNameTitle, text);
  }

  set comment(String? text) {
    _comment = text;
    if (text != null) {
      setInnerTextOfChildElementOrCreateOne(node, _elementNameComment, text,
          create: true);
    } else {
      removeChildElements(node, _elementNameComment);
    }
  }

  set repositoryId(String? text) {
    _repositoryId = text;
    if (text != null) {
      setInnerTextOfChildElementOrCreateOne(
          node, _elementNameRepositoryId, text,
          after: _elementNameCreationTime, create: true);
    } else {
      removeChildElements(node, _elementNameRepositoryId);
    }
  }

  set creationTime(DateTime now) {
    _creationTime = now;
    setInnerTextOfChildElement(
        node, _elementNameCreationTime, formatTimeString(now));
  }

  void updateDocumentId() {
    identifier = createUUID();
  }

  void updateDocumentCreationTime() {
    creationTime = getTime();
  }
}
