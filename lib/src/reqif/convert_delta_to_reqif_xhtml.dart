// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:xml/xml.dart' as xml;
import 'package:flutter_quill/quill_delta.dart' as quill;

const String _uri = 'http://www.w3.org/1999/xhtml';

enum TextSegmentType {
  bold,
  italic,
  strike,
  underline,
  line,
  root,
  bulletListItem,
  bulletList,
  text
}

class XHtmlAttribute {
  bool isActive = false;
  String key;
  TextSegmentType type;
  String tag;
  Map<String, String> tagAttributes;

  XHtmlAttribute(
      {required this.key,
      required this.type,
      required this.tag,
      this.tagAttributes = const {}});

  void insertAttributeToXML(xml.XmlBuilder builder, void Function() nested) {
    isActive = true;
    builder.element(tag,
        namespace: _uri, attributes: tagAttributes, nest: nested);
    isActive = false;
  }
}

class TextSegment {
  TextSegment? parent;
  List<TextSegment> children;
  TextSegmentType type;
  String text;

  TextSegment({this.parent, required this.type, this.text = ""})
      : children = <TextSegment>[];

  bool isActive(TextSegmentType attribute) {
    if (type == attribute) {
      return true;
    }
    if (parent != null) {
      return parent!.isActive(attribute);
    }
    return false;
  }

  void build(xml.XmlBuilder lineBuilder) {
    switch (type) {
      case TextSegmentType.text:
        lineBuilder.text(text);
      case TextSegmentType.bold:
        lineBuilder.element("strong", namespace: _uri, nest: () {
          _buildChildren(lineBuilder);
        });
      case TextSegmentType.italic:
        lineBuilder.element("i", namespace: _uri, nest: () {
          _buildChildren(lineBuilder);
        });
      case TextSegmentType.strike:
        lineBuilder.element("cite",
            namespace: _uri,
            attributes: {"style": "text-decoration:line-through"}, nest: () {
          _buildChildren(lineBuilder);
        });
      case TextSegmentType.underline:
        lineBuilder.element("cite",
            namespace: _uri,
            attributes: {"style": "text-decoration:underline"}, nest: () {
          _buildChildren(lineBuilder);
        });
      case TextSegmentType.line:
        _buildChildren(lineBuilder);
        lineBuilder.element('br', namespace: _uri);
      case TextSegmentType.bulletListItem:
        lineBuilder.element("li", namespace: _uri, nest: () {
          _buildChildren(lineBuilder);
        });
      case TextSegmentType.bulletList:
        lineBuilder.element("ul", namespace: _uri, nest: () {
          _buildChildren(lineBuilder);
        });
      case TextSegmentType.root:
        lineBuilder.element("div", namespace: _uri, nest: () {
          _buildChildren(lineBuilder);
        });
    }
  }

  void _buildChildren(xml.XmlBuilder lineBuilder) {
    assert(text == "");
    for (var element in children) {
      element.build(lineBuilder);
    }
  }

  // Pushes a text node as child.
  void pushText(String text) {
    children
        .add(TextSegment(type: TextSegmentType.text, text: text, parent: this));
  }

  // Does nothing if attribute is already active. if not active, a child will be created and returned.
  TextSegment pushAttribute(TextSegmentType type) {
    if (isActive(type)) {
      return this;
    }
    children.add(TextSegment(type: type, parent: this));
    return children.last;
  }

  // walk up the tree until the attribute is no longer active, then return this segment.
  TextSegment popAttribute(TextSegmentType type) {
    if (!isActive(type)) {
      return this;
    }
    TextSegment? ancestor = parent;
    while (ancestor != null && ancestor.isActive(type)) {
      ancestor = ancestor.parent;
    }
    if (ancestor == null) {
      throw "Internal error: conversion tree is not correctly built! No parent without active attributes!";
    }
    return ancestor;
  }
}

class XhtmlTree {
  TextSegment root;
  XhtmlTree() : root = TextSegment(type: TextSegmentType.root);

  xml.XmlNode build() {
    xml.XmlBuilder builder = xml.XmlBuilder();
    builder.namespace(_uri, 'reqif-xhtml');
    root.build(builder);
    return builder.buildDocument().firstElementChild!;
  }

  void pushLine(TextSegment line) {
    if (line.type == TextSegmentType.line) {
      line.parent = root;
      root.children.add(line);
    } else if (line.type == TextSegmentType.bulletListItem) {
      if (root.children.isEmpty ||
          root.children.last.type != TextSegmentType.bulletList) {
        root.children
            .add(TextSegment(type: TextSegmentType.bulletList, parent: root));
      }
      line.parent = root.children.last;
      root.children.last.children.add(line);
    } else {
      throw "Internal error: You can only push line and bulletListItem to the root node!";
    }
  }
}

class DeltaToXhtmlConverter {
  final List<XHtmlAttribute> _attributes = [
    XHtmlAttribute(
        key: "strike",
        type: TextSegmentType.strike,
        tag: 'cite',
        tagAttributes: {"style": "text-decoration:line-through"}),
    XHtmlAttribute(key: "bold", type: TextSegmentType.bold, tag: 'strong'),
    XHtmlAttribute(key: "italic", type: TextSegmentType.italic, tag: 'i'),
    XHtmlAttribute(
        key: "underline",
        type: TextSegmentType.underline,
        tag: 'cite',
        tagAttributes: {"style": "text-decoration:underline"}),
  ];

  XhtmlTree tree;
  TextSegment currentLine;
  late TextSegment current;

  DeltaToXhtmlConverter()
      : tree = XhtmlTree(),
        currentLine = TextSegment(type: TextSegmentType.line) {
    current = currentLine;
  }

  bool get anyAttributesPushed {
    return _attributes.any((element) => current.isActive(element.type));
  }

  void _popAttributes(Map<String, dynamic>? attributes) {
    for (final attr in _attributes) {
      if (attributes == null ||
          attributes.containsKey(attr.key) == false ||
          attributes[attr.key] == false) {
        current = current.popAttribute(attr.type);
      }
    }
  }

  void _pushAttributes(Map<String, dynamic>? attributes) {
    for (final attr in _attributes) {
      if (attributes != null &&
          attributes.containsKey(attr.key) &&
          attributes[attr.key]) {
        current = current.pushAttribute(attr.type);
      }
    }
  }

  bool _isLineAttribute(String text) {
    return text == '\n';
  }

  void _pushLineAttributesAndStartNextLine(Map<String, dynamic>? attributes) {
    if (attributes != null) {
      if (attributes.containsKey("list") && attributes["list"] == "bullet") {
        currentLine.type = TextSegmentType.bulletListItem;
      }
    }
    _startNextLine();
  }

  void _startNextLine() {
    tree.pushLine(currentLine);
    currentLine = TextSegment(type: TextSegmentType.line);
    current = currentLine;
  }

  xml.XmlNode deltaToXhtml(quill.Delta delta) {
    for (final operation in delta.operations) {
      if (operation.key != "insert") {
        throw "Only insert operations are supported";
      }
      if (operation.value is String) {
        if (_isLineAttribute(operation.value)) {
          _pushLineAttributesAndStartNextLine(operation.attributes);
        } else {
          String text = operation.value;
          if (text.contains('\n')) {
            final lines = text.split('\n');
            final bool startNewLineOnLast = text.endsWith('\n');
            if (startNewLineOnLast) {
              lines.removeLast();
            }
            for (int i = 0; i < lines.length; ++i) {
              _changeAttributesAndPushText(operation.attributes, lines[i]);
              if (i < lines.length - 1 || startNewLineOnLast) {
                _startNextLine();
              }
            }
          } else {
            _changeAttributesAndPushText(operation.attributes, operation.value);
          }
        }
      }
      // TODO images
    }
    return tree.build();
  }

  void _changeAttributesAndPushText(
      Map<String, dynamic>? attributes, String text) {
    _popAttributes(attributes);
    _pushAttributes(attributes);
    current.pushText(text);
  }
}
