// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_spec_type.dart';
import 'package:xml/xml.dart' as xml;

/// This class describes the names and data types of the specification objects
/// that belong to this specification object.
class ReqIfSpecificationType extends ReqIfSpecType {
  static const String xmlName = 'SPECIFICATION-TYPE';

  ReqIfSpecificationType.parse(xml.XmlElement node, ReqIfDocument document)
      : super.parse(
            node, document, ReqIfElementTypes.specificationType, xmlName);
}
