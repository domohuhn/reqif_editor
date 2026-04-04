// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:reqif_editor/src/document/document_data.dart';
import 'package:xml/xml.dart' as xml;
import 'package:reqif_editor/src/reqif/convert_common.dart';
import 'package:reqif_editor/src/reqif/bullet_list.dart';

typedef ConversionError = Exception;

/// Keeps tack of the styles pushed in parent nodes.
class _XhtmlTextStyles {
  _XhtmlTextStyles();

  /// Deep copy.
  _XhtmlTextStyles.from(_XhtmlTextStyles other)
      : italic = other.italic,
        bold = other.bold,
        strike = other.strike,
        underline = other.underline,
        leftMargin = other.leftMargin;

  bool italic = false;
  bool bold = false;
  bool strike = false;
  bool underline = false;
  int leftMargin = 0;

  TextStyle apply(TextStyle input) {
    return input.copyWith(
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        decoration: _getDecoration());
  }

  TextDecoration? _getDecoration() {
    if (strike && underline) {
      return TextDecoration.combine(
          [TextDecoration.underline, TextDecoration.lineThrough]);
    }
    if (strike) {
      return TextDecoration.lineThrough;
    }
    if (underline) {
      return TextDecoration.underline;
    }
    return null;
  }
}

class XHtmlToWidgetsConverter extends StatelessWidget {
  const XHtmlToWidgetsConverter(
      {super.key, required this.node, required this.cache});

  final xml.XmlNode node;
  final DocumentData cache;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(5),
        child: Column(children: xhtmlToWidgetList(node)));
  }

  List<Widget> xhtmlToWidgetList(xml.XmlNode node) {
    List<Widget> widgets = [];
    List<InlineSpan> currentTextSpan = [];
    TextStyle style = const TextStyle();
    for (final node in node.findAllElements("THE-VALUE")) {
      _XhtmlTextStyles attributes = _XhtmlTextStyles();
      _recurseThroughDOM(widgets, node, attributes, style, currentTextSpan);
    }
    _pushCollectedTextsToList(widgets, currentTextSpan);
    return widgets;
  }

  /// Pushes the collected texts as rich text to the widget list.
  /// Removes the last entry if it is a new line.
  ///
  /// Should only be called if you want to finalize the text, either before creating a list or image,
  /// or at the end of the widget creation.
  void _pushCollectedTextsToList(
      List<Widget> widgets, List<InlineSpan> currentTextSpan) {
    if (widgets.isEmpty) {
      // drop all text segments that are only whitespace before any text was added.
      int countToDrop = 0;
      for (final t in currentTextSpan) {
        if (t.toPlainText().trim().isEmpty) {
          countToDrop += 1;
        } else {
          break;
        }
      }
      currentTextSpan.removeRange(0, countToDrop);
    }
    while (lastLineEndsWithNewline(currentTextSpan) ||
        lastLineIsOnlyWhiteSpace(currentTextSpan)) {
      currentTextSpan.removeLast();
    }
    if (currentTextSpan.isNotEmpty) {
      widgets.add(Container(
          alignment: Alignment.centerLeft,
          child: Text.rich(TextSpan(children: [...currentTextSpan]))));
    }
    currentTextSpan.clear();
  }

  void _recurseThroughDOM(
      List<Widget> widgets,
      xml.XmlNode node,
      _XhtmlTextStyles attributes,
      TextStyle ctx,
      List<InlineSpan> currentTextSpan) {
    var nextAttributes = _pushStyles(node, attributes);
    if (isHtmlDomElement(node, 'ul')) {
      _pushCollectedTextsToList(widgets, currentTextSpan);
      List<Widget> listItems = [];
      // collect new list from children - must be li items according to html spec
      for (final node in node.childElements) {
        List<Widget> subItems = [];
        if (!isListItem(node)) {
          throw ConversionError(
              "Invalid Reqif HTML: Direct children of a 'ul' node must be 'li' nodes!");
        }
        _recurseThroughDOM(
            subItems, node, nextAttributes, ctx, currentTextSpan);
        _pushCollectedTextsToList(subItems, currentTextSpan);
        if (subItems.isNotEmpty) {
          listItems.addAll(subItems);
        }
      }
      widgets.add(BulletList(listItems));
      return;
    }
    if (isHtmlDomElement(node, 'object')) {
      node as xml.XmlElement;
      final child = node.getElement('object', namespace: '*');
      Image? image;
      final objectType = node.getAttribute('type');
      if (objectType == "image/png") {
        final provider = cache.getCachedImageOrLoad(node.getAttribute('data'));
        if (provider != null) image = Image(image: provider);
      }
      if (image == null &&
          child != null &&
          child.getAttribute('type') == "image/png") {
        final provider = cache.getCachedImageOrLoad(child.getAttribute('data'));
        if (provider != null) image = Image(image: provider);
      }
      if (image == null) {
        var errorString =
            'FAILED TO LOAD OBJECT\n"${node.getAttribute('data')}"\nOF TYPE "$objectType".';
        if (child != null) {
          errorString += ' Alternative Text:\n';
        }
        currentTextSpan.add(TextSpan(
            text: errorString,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)));
        if (child != null) {
          for (final node in child.nodes) {
            _recurseThroughDOM(
                widgets, node, nextAttributes, ctx, currentTextSpan);
          }
        }
      } else {
        _pushCollectedTextsToList(widgets, currentTextSpan);
        widgets.add(image);
      }
      return;
    }
    if (isHtmlDomElement(node, 'p') &&
        !lastLineEndsWithNewline(currentTextSpan)) {
      currentTextSpan.add(TextSpan(text: '\n', style: attributes.apply(ctx)));
    }
    _addToRichText(node, nextAttributes, ctx, currentTextSpan);
    for (final node in node.nodes) {
      _recurseThroughDOM(widgets, node, nextAttributes, ctx, currentTextSpan);
    }
    if (isHtmlDomElement(node, 'p') &&
        !lastLineEndsWithNewline(currentTextSpan)) {
      currentTextSpan.add(TextSpan(text: '\n', style: attributes.apply(ctx)));
    }
  }

  bool lastLineIsOnlyWhiteSpace(List<InlineSpan> spans) {
    if (spans.isEmpty) {
      return false;
    }
    final text = spans.last.toPlainText().trim();
    return text.isEmpty;
  }

  bool lastLineEndsWithNewline(List<InlineSpan> spans) {
    if (spans.isEmpty) {
      return false;
    }
    final text = spans.last.toPlainText();
    final cus = text.codeUnits;
    bool val = cus.isNotEmpty && (cus.last == 10 || cus.last == 13);
    return val;
  }

  _XhtmlTextStyles _pushStyles(xml.XmlNode node, _XhtmlTextStyles attributes) {
    if (node is xml.XmlElement) {
      final copy = _XhtmlTextStyles.from(attributes);

      if (node.localName == 'strong') {
        copy.bold = true;
      }
      if (node.localName == 'b') {
        copy.bold = true;
      }
      if (node.localName == 'em') {
        copy.italic = true;
      }
      if (node.localName == 'i') {
        copy.italic = true;
      }
      if (node.localName == 'u') {
        copy.underline = true;
      }
      if (node.localName == 'del') {
        copy.strike = true;
      }
      if (node.localName == 's') {
        copy.strike = true;
      }

      final style = node.getAttribute('style');
      if (style != null) {
        if (parseStrikeThroughFromStyle(style)) {
          copy.strike = true;
        }
        if (parseUnderLineFromStyle(style)) {
          copy.underline = true;
        }
        copy.leftMargin += parseLeftMarginFromStyle(style);
      }
      return copy;
    }
    return attributes;
  }

  String _indentText(String text, _XhtmlTextStyles attributes) {
    final int spaces = (attributes.leftMargin / 4).round();
    if (spaces > 0) {
      return ' ' * spaces + text;
    }
    return text;
  }

  void _addToRichText(xml.XmlNode element, _XhtmlTextStyles attributes,
      TextStyle ctx, List<InlineSpan> currentTextSpan) {
    if (element is xml.XmlText) {
      // drop all new lines except explicit br and p
      final text = element.value.replaceAll('\n', '').replaceAll('\r', '');
      if (text.isNotEmpty) {
        currentTextSpan.add(TextSpan(
            text: _indentText(text, attributes), style: attributes.apply(ctx)));
      }
    }
    if (element is xml.XmlElement) {
      if (element.localName == "br") {
        currentTextSpan.add(TextSpan(text: '\n', style: attributes.apply(ctx)));
      }
    }
  }
}
