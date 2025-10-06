// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:convert';
import 'dart:math';

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
  return escapeSpecialCharacters(doc.toXmlString(pretty: false));
}

/// Converts the XML tree in [doc] to a string and writes the contents to the file [outputPath].
void writeXMLToFile(
    String outputPath, xml.XmlDocument doc, DocumentService system) {
  system.writeFileSync(outputPath, convertXMLToString(doc));
}

List<int> _findAllSubstrings(String text, String search) {
  RegExp regex = RegExp(search);
  Iterable<RegExpMatch> matches = regex.allMatches(text);
  List<int> indices = [];
  for (RegExpMatch match in matches) {
    indices.add(match.start);
  }
  return indices;
}

bool _isInValueRange(int idx, int block, List<int> starts, List<int> ends) {
  if (starts.length == ends.length && block < starts.length) {
    final startIdx = max(0, block);
    return starts[startIdx] < idx && idx < ends[startIdx];
  }
  return false;
}

/// escapes the same characters as the PTC requirements connector seems to escape.
String escapeSpecialCharacters(String input) {
  final starts = _findAllSubstrings(input, "<THE-VALUE");
  final ends = _findAllSubstrings(input, "</THE-VALUE");
  StringBuffer buffer = StringBuffer();
  int counter = 0;
  int currentValueBlock = 0;
  int bracketCount = 0;
  bool inAttribute = false;
  int attributeStart = 0;
  for (int pt in input.codeUnits) {
    // count open and close tags < (60) and > (62)
    if (pt == 60 && !inAttribute) bracketCount += 1;
    // start/end an attribute whenever we see a matching pair of ' or " (34 and 39)
    final wasAttribute = inAttribute;
    if (inAttribute && attributeStart == pt) {
      attributeStart = 0;
      inAttribute = false;
    } else if (bracketCount > 0 && !inAttribute && (pt == 34 || pt == 39)) {
      attributeStart = pt;
      inAttribute = true;
    }
    if (pt == 62 && !inAttribute) bracketCount -= 1;
    // escape closing tags in text sections:
    final bool escapeBracket = (bracketCount < 0 || inAttribute) && pt == 62;
    // escape tabs, ', " in the-value blocks:
    final bool relevantCharacter =
        (pt == 34 || pt == 39 || pt == 9 || pt == 37 || pt == 94);
    final bool escapeInAttribute =
        inAttribute && pt != attributeStart && (pt == 37 || pt == 39);
    final bool escapeInValue = relevantCharacter &&
        !inAttribute &&
        !wasAttribute &&
        _isInValueRange(counter, currentValueBlock, starts, ends);
    bracketCount = max(bracketCount, 0);
    if (pt < 127 &&
        pt != 124 &&
        !escapeBracket &&
        !escapeInValue &&
        !escapeInAttribute) {
      buffer.write(ascii.decode([pt]));
    } else {
      if (escapeBracket) {
        buffer.write('&gt;');
      } else if (pt == 34) {
        buffer.write('&quot;');
      } else if (pt == 39) {
        buffer.write('&#039;');
      } else {
        buffer.write('&#x${pt.toRadixString(16).toUpperCase()};');
      }
    }
    final checkIdx = max(0, currentValueBlock);
    if (checkIdx < ends.length && counter >= ends[checkIdx]) {
      currentValueBlock += 1;
    }
    ++counter;
  }
  return buffer.toString();
}
