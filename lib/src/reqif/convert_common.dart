// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:xml/xml.dart' as xml;

// input [node] must be a reqif ATTRIBUTE-VALUE-XHTML node.
// Output is a quill delta text.
String reqIfNodeToHtmlFragment(xml.XmlNode node) {
  int valueCount = 0;
  String rv = "";
  for (final content in node.findElements("THE-VALUE")) {
    valueCount++;
    if (valueCount > 1) {
      throw "Only one value is allowed in valid reqif documents!";
    }
    final htmlFragment = stripSurroundingTags(
        content.toString().replaceAll('reqif-xhtml:', ''),
        "<THE-VALUE>",
        "</THE-VALUE>");
    rv = htmlFragment;
  }
  return rv;
}

String stripSurroundingTags(
    String input, String startString, String endString) {
  final start = input.indexOf(startString);
  final end = input.indexOf(endString);
  return input.substring(start + startString.length, end);
}

final RegExp _underline = RegExp(r'text-decoration:[^;]*underline');
final RegExp _strikeThrough = RegExp(r'text-decoration:[^;]*line-through');

bool parseUnderLineFromStyle(String style) {
  return _underline.hasMatch(style);
}

bool parseStrikeThroughFromStyle(String style) {
  return _strikeThrough.hasMatch(style);
}

bool isHtmlDomElement(xml.XmlNode element, String localName) {
  if (element is xml.XmlElement) {
    return element.localName == localName;
  }
  return false;
}

bool isListItem(xml.XmlNode element) {
  return isHtmlDomElement(element, 'li');
}
