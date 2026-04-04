// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/reqif/convert_common.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter_quill/quill_delta.dart' as quill;
import 'package:reqif_editor/src/reqif/convert_delta_to_reqif_xhtml.dart';
import 'package:reqif_editor/src/reqif/convert_reqif_xhtml_to_delta.dart';

/// Converts the formatted text in the quill [delta] format
/// to reqif xhtml nodes.
///
/// If [useParagraphs] is set to true, the conversion will use
/// p tags instead of br for newlines.
xml.XmlNode deltaToXhtml(quill.Delta delta, bool useParagraphs) {
  DeltaToXhtmlConverter converter = DeltaToXhtmlConverter(useParagraphs);
  return converter.deltaToXhtml(delta);
}

/// Checks if there are paragraphs in the xhtml in [node].
///
/// This method searches for a p tag.
bool xhtmlHasParagraphs(xml.XmlNode node) {
  bool rv = false;
  for (final d in node.descendantElements) {
    if (isParagraphItem(d)) {
      return true;
    }
  }
  return rv;
}

/// Converts the xml input [node] to delta formatted text.
/// [node] must be a reqif ATTRIBUTE-VALUE-XHTML node.
quill.Delta deltaFromReqIfNode(xml.XmlNode node) {
  XHtmlToDeltaConverter converter = XHtmlToDeltaConverter();
  return converter.deltaFromReqIfNode(node);
}
