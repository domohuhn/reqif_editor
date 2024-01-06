// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:convert';

import 'package:xml/xml.dart' as xml;
import 'package:reqif_editor/src/document/document_service.dart';

/// Parses the ReqIF document stored in [path].
xml.XmlDocument readReqIFToXML(String path, DocumentService system) {
  if (!system.fileExistsSync(path)) {
    throw 'File "$path" does not exist!';
  }
  return parseXMLString(system.readFileSync(path));
}

/// Parses an XML string with the given [contents]
xml.XmlDocument parseXMLString(String contents) {
  final document = xml.XmlDocument.parse(contents);
  return document;
}

String convertXMLToString(xml.XmlDocument doc) {
  return _escapeSpecialCharacters(doc.toXmlString(pretty: false));
}

/// Converts the XML tree in [doc] to a string and writes the contents to the file [outputPath].
void writeXMLToFile(
    String outputPath, xml.XmlDocument doc, DocumentService system) {
  system.writeFileSync(outputPath, convertXMLToString(doc));
}

/// escapes the same characters DOORS seems to escape.
String _escapeSpecialCharacters(String input) {
  String converted = "";
  for (int pt in input.codeUnits) {
    if (pt < 127 && pt != 91 && pt != 93 && pt != 9) {
      converted += ascii.decode([pt]);
    } else {
      converted += '&#$pt;';
    }
  }
  return converted;
}
