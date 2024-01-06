// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:xml/xml.dart' as xml;
import 'package:flutter_quill/quill_delta.dart' as quill;
import 'package:reqif_editor/src/reqif/convert_delta_to_reqif_xhtml.dart';
import 'package:reqif_editor/src/reqif/convert_reqif_xhtml_to_delta.dart';

/// Converts the formatted text in the quill [delta] format
/// to reqif xhtml nodes.
xml.XmlNode deltaToXhtml(quill.Delta delta) {
  DeltaToXhtmlConverter converter = DeltaToXhtmlConverter();
  return converter.deltaToXhtml(delta);
}

/// Converts the xml input [node] to delta formatted text.
/// [node] must be a reqif ATTRIBUTE-VALUE-XHTML node.
quill.Delta deltaFromReqIfNode(xml.XmlNode node) {
  XHtmlToDeltaConverter converter = XHtmlToDeltaConverter();
  return converter.deltaFromReqIfNode(node);
}
