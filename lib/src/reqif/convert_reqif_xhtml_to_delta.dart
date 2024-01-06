// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:xml/xml.dart' as xml;
import 'package:flutter_quill/quill_delta.dart' as quill;
import 'package:reqif_editor/src/reqif/convert_common.dart';

class XHtmlToDeltaConverter {
  // input [node] must be a reqif ATTRIBUTE-VALUE-XHTML node.
  // Output is a quill delta text.
  quill.Delta deltaFromReqIfNode(xml.XmlNode node) {
    return xhtmlToDelta(node);
  }

  quill.Delta xhtmlToDelta(xml.XmlNode node) {
    var delta = quill.Delta();

    for (final node in node.findAllElements("THE-VALUE")) {
      Map<String, dynamic> attributes = {};
      recurseThroughDOM(delta, node, attributes);
    }
    _insertNewLineIfMissing(delta);

    return delta;
  }

  void recurseThroughDOM(
      quill.Delta delta, xml.XmlNode xml, Map<String, dynamic> attributes) {
    var nextAttributes = _pushStyles(xml, attributes);
    addToDelta(delta, xml, nextAttributes);
    for (final node in xml.nodes) {
      recurseThroughDOM(delta, node, nextAttributes);
    }
    if (isListItem(xml)) {
      nextAttributes['list'] = _listType;
      _insertWithAttributes(delta, nextAttributes, '\n');
    }
  }

  String _listType = "";

  Map<String, dynamic> _pushStyles(
      xml.XmlNode element, Map<String, dynamic> attributes) {
    if (element is xml.XmlElement) {
      Map<String, dynamic> copy = {};
      copy.addAll(attributes);

      if (element.localName == 'ol') {
        // TODO numbered lists! _listType = 'ordered';
        _listType = 'bullet';
      }
      if (element.localName == 'ul') {
        _listType = 'bullet';
      }
      if (element.localName == 'strong') {
        copy['bold'] = true;
      }
      if (element.localName == 'b') {
        copy['bold'] = true;
      }
      if (element.localName == 'em') {
        copy['italic'] = true;
      }
      if (element.localName == 'i') {
        copy['italic'] = true;
      }
      if (element.localName == 'u') {
        copy['underline'] = true;
      }
      if (element.localName == 'del') {
        copy['strike'] = true;
      }
      if (element.localName == 's') {
        copy['strike'] = true;
      }

      final style = element.getAttribute('style');
      if (style != null) {
        if (parseStrikeThroughFromStyle(style)) {
          copy['strike'] = true;
        }
        if (parseUnderLineFromStyle(style)) {
          copy['underline'] = true;
        }
      }
      return copy;
    }
    return attributes;
  }

  void addToDelta(
      quill.Delta delta, xml.XmlNode element, Map<String, dynamic> attributes) {
    if (element is xml.XmlText) {
      if (attributes.containsKey("list")) {
        final copy = Map<String, dynamic>.from(attributes);
        copy.remove("list");
        _insertWithAttributes(delta, copy, element.value);
        _insertWithAttributes(delta, attributes, '\n');
      } else {
        _insertWithAttributes(delta, attributes, element.value);
      }
    }
    if (element is xml.XmlElement) {
      if (element.localName == "br") {
        _insertWithAttributes(delta, {}, "\n");
      }
      if (element.localName == "ul" || element.localName == "ol") {
        _insertNewLineIfMissing(delta, attributes);
      }
      // TODO type object for images / videos / sound files
    }
  }

  void _insertNewLineIfMissing(quill.Delta delta,
      [Map<String, dynamic> attributes = const {}]) {
    if (!delta.last.value.toString().endsWith("\n")) {
      delta.insert('\n', attributes);
    }
  }

  void _insertWithAttributes(
      quill.Delta delta, Map<String, dynamic> attributes, String text) {
    if (attributes.isNotEmpty) {
      delta.insert(text, attributes);
    } else {
      delta.insert(text);
    }
  }
}
