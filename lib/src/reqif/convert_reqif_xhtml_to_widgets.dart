// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:reqif_editor/src/document/document_data.dart';
import 'package:xml/xml.dart' as xml;
import 'package:reqif_editor/src/reqif/convert_common.dart';
import 'package:reqif_editor/src/reqif/widget_list.dart';

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
    final converted = xhtmlToWidgetList(node, context);
    if (converted.isNotEmpty) {
      return Padding(
          padding: const EdgeInsets.all(5), child: Column(children: converted));
    } else {
      return Padding(padding: const EdgeInsets.all(5));
    }
  }

  List<Widget> xhtmlToWidgetList(xml.XmlNode node, BuildContext context) {
    try {
      List<Widget> widgets = [];
      List<InlineSpan> currentTextSpan = [];
      TextStyle style = const TextStyle();
      for (final node in node.findAllElements("THE-VALUE")) {
        _XhtmlTextStyles attributes = _XhtmlTextStyles();
        _recurseThroughDOM(
            widgets, node, attributes, style, currentTextSpan, context);
      }
      _pushCollectedTextsToList(widgets, currentTextSpan);
      return widgets;
    } catch (e) {
      return [
        Text.rich(TextSpan(
            text: 'FAILED TO CONVERT ATTRIBUTE DUE TO ERROR:\n"$e"\n',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)))
      ];
    }
  }

  /// Pushes the collected texts as rich text to the widget list.
  /// Removes the last entry if it is a new line.
  ///
  /// Should only be called if you want to finalize the text, either before creating a list or image,
  /// or at the end of the widget creation.
  void _pushCollectedTextsToList(
      List<Widget> widgets, List<InlineSpan> currentTextSpan,
      [EdgeInsetsGeometry? padding]) {
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
          padding: padding,
          child: Text.rich(TextSpan(children: [...currentTextSpan]))));
    }
    currentTextSpan.clear();
  }

  TableRow _collectTableRow(xml.XmlNode node, _XhtmlTextStyles attributes,
      TextStyle ctx, BuildContext context) {
    List<Widget> row = [];

    for (final element in node.childElements) {
      if (isHtmlDomElement(element, 'th') || isHtmlDomElement(element, 'td')) {
        List<Widget> widgets = [];
        List<InlineSpan> currentTextSpan = [];
        _recurseThroughDOM(
            widgets, element, attributes, ctx, currentTextSpan, context);
        _pushCollectedTextsToList(widgets, currentTextSpan);
        if (widgets.isNotEmpty) {
          if (widgets.length > 1) {
            row.add(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                child: Column(children: widgets)));
          } else {
            row.add(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                child: widgets.first));
          }
        } else {
          // placeholder for empty rows
          row.add(const Text(''));
        }
      } else {
        throw ConversionError(
            "Invalid Reqif XHTML: A 'tr' can only have 'th' and 'td' as children, not $element!");
      }
    }
    return TableRow(children: row);
  }

  void _parseTable(
      List<Widget> widgets,
      xml.XmlNode node,
      _XhtmlTextStyles attributes,
      TextStyle textStyle,
      BuildContext buildContext) {
    const double tableTopBottomMargin = 32.0;
    bool hadCaption = false;
    List<TableRow> rows = [];
    for (final tr in node.childElements) {
      if (isHtmlDomElement(tr, 'caption')) {
        if (rows.isEmpty && !hadCaption) {
          hadCaption = true;
          List<InlineSpan> currentTextSpan = [];
          _recurseThroughDOM(widgets, tr, attributes, textStyle,
              currentTextSpan, buildContext);
          _pushCollectedTextsToList(widgets, currentTextSpan,
              const EdgeInsets.fromLTRB(0, tableTopBottomMargin, 0, 0));
        } else {
          throw ConversionError(
              "Invalid Reqif XHTML: A 'caption' must be the first child of a table before any rows and there can be only one caption per table!");
        }
      } else if (isHtmlDomElement(tr, 'thead') ||
          isHtmlDomElement(tr, 'tbody') ||
          isHtmlDomElement(tr, 'tfoot')) {
        for (final nested in tr.childElements) {
          if (isHtmlDomElement(nested, 'tr')) {
            final row =
                _collectTableRow(nested, attributes, textStyle, buildContext);
            rows.add(row);
          } else {
            throw ConversionError(
                "Invalid Reqif XHTML: A 'thead', 'tbody' or 'tfoot' can only have 'tr' as children!");
          }
        }
      } else if (isHtmlDomElement(tr, 'tr')) {
        final row = _collectTableRow(tr, attributes, textStyle, buildContext);
        rows.add(row);
      }
    }

    final borderColor = Theme.of(buildContext).colorScheme.outlineVariant;
    final table = Table(
      border: TableBorder.all(width: 2.0, color: borderColor),
      children: rows,
    );
    widgets.add(Container(
        margin: EdgeInsets.fromLTRB(
            0, hadCaption ? 0 : tableTopBottomMargin, 0, tableTopBottomMargin),
        child: table));
    return;
  }

  void _recurseThroughDOM(
      List<Widget> widgets,
      xml.XmlNode node,
      _XhtmlTextStyles attributes,
      TextStyle textStyle,
      List<InlineSpan> currentTextSpan,
      BuildContext buildContext) {
    var nextAttributes = _pushStyles(node, attributes);
    final isUnorderedList = isHtmlDomElement(node, 'ul');
    final isOrderedList = isHtmlDomElement(node, 'ol');
    final isTable = isHtmlDomElement(node, 'table');
    if (isUnorderedList || isOrderedList) {
      _pushCollectedTextsToList(widgets, currentTextSpan);
      List<Widget> listItems = [];
      // collect new list from children - must be li items according to html spec
      for (final node in node.childElements) {
        List<Widget> subItems = [];
        if (!isListItem(node)) {
          throw ConversionError(
              "Invalid Reqif HTML: Direct children of a 'ul' or 'ol' node must be 'li' nodes!");
        }
        _recurseThroughDOM(subItems, node, nextAttributes, textStyle,
            currentTextSpan, buildContext);
        _pushCollectedTextsToList(subItems, currentTextSpan);
        if (subItems.isNotEmpty) {
          listItems.addAll(subItems);
        }
      }
      widgets.add(WidgetList(
        listItems,
        isOrdered: isOrderedList,
      ));
      return;
    }
    if (isTable) {
      _pushCollectedTextsToList(widgets, currentTextSpan);
      _parseTable(widgets, node, attributes, textStyle, buildContext);
      return;
    }

    if (isHtmlDomElement(node, 'object')) {
      node as xml.XmlElement;
      final child = node.getElement('object', namespaceUri: '*');
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
            _recurseThroughDOM(widgets, node, nextAttributes, textStyle,
                currentTextSpan, buildContext);
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
      currentTextSpan
          .add(TextSpan(text: '\n', style: attributes.apply(textStyle)));
    }
    _addToRichText(node, nextAttributes, textStyle, currentTextSpan);
    for (final node in node.nodes) {
      _recurseThroughDOM(widgets, node, nextAttributes, textStyle,
          currentTextSpan, buildContext);
    }
    if (isHtmlDomElement(node, 'p') &&
        !lastLineEndsWithNewline(currentTextSpan)) {
      currentTextSpan
          .add(TextSpan(text: '\n', style: attributes.apply(textStyle)));
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
