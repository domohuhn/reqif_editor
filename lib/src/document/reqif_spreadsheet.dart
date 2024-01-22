// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:reqif_editor/src/document/column_header.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/document/resizable_table_view.dart';
import 'package:reqif_editor/src/reqif/convert_reqif_xhtml_to_widgets.dart';
import 'package:reqif_editor/src/reqif/flat_document.dart';
import 'package:reqif_editor/src/reqif/reqif_attribute_values.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_data_types.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class ReqIfSpreadSheet extends StatefulWidget {
  final DocumentController controller;
  final QuillController editorController;
  final void Function(dynamic) onNewQuillEditor;
  final void Function() onNewFilterValue;
  final bool isEditable;
  final bool filterIsEnabled;

  /// Forces all values to editable.
  /// Ignores the values requested by the document controller.
  /// This exists mainly for testing purposes.
  final bool forceEditable;

  DocumentData get data => controller.visibleData;
  bool get hasData =>
      controller.visibleDocumentNumber >= 0 &&
      controller.visibleDocumentNumber < controller.length;
  bool get hasPart =>
      hasData &&
      controller.visibleDocumentPartNumber >= 0 &&
      controller.visibleDocumentPartNumber < data.flatDocument.partCount;
  ReqIfDocumentPart get part => controller.visiblePart;

  /// index of the visible document
  int get document => controller.visibleDocumentNumber;

  /// index of the visible document part
  int get partNumber => controller.visibleDocumentPartNumber;

  void wasModified() {
    controller.documentWasModified(controller.visibleDocumentNumber);
  }

  const ReqIfSpreadSheet(
      {required this.controller,
      required this.editorController,
      required this.onNewQuillEditor,
      required this.filterIsEnabled,
      required this.onNewFilterValue,
      super.key,
      this.isEditable = true,
      this.forceEditable = false});

  @override
  State<ReqIfSpreadSheet> createState() => _ReqIfSpreadSheetState();
}

class _ReqIfSpreadSheetState extends State<ReqIfSpreadSheet> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final FocusNode editorFocusNode = FocusNode();

  Widget _buildQuillEditor() {
    return QuillEditor.basic(
      configurations: QuillEditorConfigurations(
        controller: widget.editorController,
        readOnly: false,
        autoFocus: true,
        expands: true,
        sharedConfigurations: const QuillSharedConfigurations(),
      ),
      focusNode: editorFocusNode,
    );
  }

  /// Cache for combo boxes
  final List<List<DropdownMenuItem<String>>?> _comboBoxDropDownLists = [];

  void _fillComboBoxLists() {
    _comboBoxDropDownLists.clear();
    for (int idx = 0;
        idx < widget.part.type.attributeDefinitions.length;
        ++idx) {
      final datatype = widget.part.type[idx];
      List<DropdownMenuItem<String>> cacheList = [];
      if (datatype.dataTypeDefinition.type ==
          ReqIfElementTypes.datatypeDefinitionEnum) {
        final enumDef = datatype.dataTypeDefinition as ReqIfDataTypeEnum;
        for (final val in enumDef.validValues) {
          cacheList.add(DropdownMenuItem<String>(value: val, child: Text(val)));
        }
        _comboBoxDropDownLists.add(cacheList);
      } else {
        _comboBoxDropDownLists.add(null);
      }
    }
    assert(_comboBoxDropDownLists.length ==
        widget.part.type.attributeDefinitions.length);
  }

  void _fillCache() {
    _fillComboBoxLists();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.documents.length <= widget.document ||
        widget.data.flatDocument.partCount == 0) {
      return const SizedBox.shrink();
    }
    final flatDocument =
        widget.controller.documents[widget.document].flatDocument;
    if (flatDocument.partCount <= widget.partNumber) {
      throw RangeError("Index out of Range: $widget._part is not in range"
          " [0, ${flatDocument.partCount}] "
          "in document ${flatDocument.title}");
    }
    _fillCache();
    final documentPart = flatDocument[widget.partNumber];
    return ResizableTableView(
        rowCount: documentPart.rowCount,
        columnCount: documentPart.columnCount,
        cellBuilder: _buildCell,
        columnHeaderBuilder: _buildColumnHeader,
        initialRowHeights: _estimateInitialRowHeights,
        initialColumnWidths: _estimateInitialColumnWidths,
        onSelectionChanged: _onSelectionChanged,
        columnWidthsProvider: () => widget.controller.columnWidths,
        rowHeightsProvider: () => widget.controller.rowHeights,
        selection: _selected,
        rowPositionBuilder: _buildRowPosition,
        searchPosition: () {
          if (widget.hasPart) {
            return widget.data.searchData[widget.partNumber].matchPosition;
          }
          return const TableVicinity(row: -1, column: -1);
        },
        scrollControllerBuilder: () {
          widget.controller.refreshScrollControllers();
          return TableViewScrollControllers(
              horizontal: widget.controller.horizontalScrollController,
              vertical: widget.controller.verticalScrollController);
        });
  }

  double defaultRowHeight = 40;
  double defaultLineHeight = 24;
  double defaultComboBoxHeight = 50;

  List<double> _estimateInitialRowHeights() {
    List<double> rowHeights = [];
    rowHeights.add(defaultRowHeight + 32);
    for (final element in widget.part.elements) {
      double rowHeight = defaultRowHeight;
      final bool rowEditable = element.isEditable && widget.isEditable;
      for (final attr in element.object.values) {
        bool columnEditable = attr.isEditable;
        switch (attr.type) {
          case ReqIfElementTypes.attributeValueEnumeration:
            attr as ReqIfAttributeValueEnum;
            if ((rowEditable && columnEditable) || widget.forceEditable) {
              rowHeight = max(rowHeight, attr.length * defaultComboBoxHeight);
            } else {
              rowHeight = max(rowHeight, attr.length * defaultLineHeight);
            }
          case ReqIfElementTypes.attributeValueString:
            attr as ReqIfAttributeValueSimple;
            final text = attr.toString();
            final Size size = (TextPainter(
                    text: TextSpan(text: text),
                    textScaler: MediaQuery.of(context).textScaler,
                    textDirection: TextDirection.ltr)
                  ..layout(maxWidth: maxTextLineWidth))
                .size;
            rowHeight = max(rowHeight, size.height + defaultTextPadding);
          case ReqIfElementTypes.attributeValueXhtml:
            attr as ReqIfAttributeValueXhtml;
            final text = attr.toStringWithNewlines();
            final Size size = (TextPainter(
                    text: TextSpan(text: text),
                    textScaler: MediaQuery.of(context).textScaler,
                    textDirection: TextDirection.ltr)
                  ..layout(maxWidth: maxTextLineWidth))
                .size;
            rowHeight = max(rowHeight, size.height + defaultTextPadding);
            if (attr.embeddedObjectCount > 0) {
              rowHeight += maxTextLineWidth * attr.embeddedObjectCount;
            }
          default:
        }
      }
      rowHeights.add(1.2 * rowHeight);
    }
    return rowHeights;
  }

  static const double defaultColumnWidth = 120;
  static const double defaultLetterWidth = 8.5;
  static const double defaultTextPadding = 10;
  static const double comboBoxLetterWidth = 7.5;
  static const double comboBoxPadding = 54;

  static const double maxTextLineWidth = 600;

  List<double> _estimateInitialColumnWidths() {
    List<double> columnWidths = [];
    if (!widget.hasData || !widget.hasPart) {
      return columnWidths;
    }
    final map = widget.data.columnMapping[widget.partNumber];
    for (int i = 0; i < widget.part.columnCount; ++i) {
      columnWidths.add(defaultColumnWidth);
    }
    for (final element in widget.part.elements) {
      final bool rowEditable = element.isEditable && widget.isEditable;
      for (int i = 0; i < widget.part.columnCount; ++i) {
        final column = map.remap(i);
        final attr = element.object[column];
        if (attr == null) {
          continue;
        }
        bool columnEditable = attr.isEditable;
        double columnWidth = columnWidths[i];
        switch (attr.type) {
          case ReqIfElementTypes.attributeValueEnumeration:
            attr as ReqIfAttributeValueEnum;
            for (final text in attr.validValues) {
              if ((rowEditable && columnEditable) || widget.forceEditable) {
                columnWidth = max(columnWidth,
                    text.length * comboBoxLetterWidth + comboBoxPadding);
              } else {
                columnWidth =
                    max(columnWidth, text.length * defaultLetterWidth);
              }
            }
          case ReqIfElementTypes.attributeValueString:
            attr as ReqIfAttributeValueSimple;
            final text = attr.toString();
            final Size size = (TextPainter(
                    text: TextSpan(text: text),
                    textScaler: MediaQuery.of(context).textScaler,
                    textDirection: TextDirection.ltr)
                  ..layout(maxWidth: maxTextLineWidth))
                .size;
            columnWidth = max(columnWidth, size.width + defaultTextPadding);
          case ReqIfElementTypes.attributeValueXhtml:
            attr as ReqIfAttributeValueXhtml;
            final text = attr.toStringWithNewlines();
            final Size size = (TextPainter(
                    text: TextSpan(text: text),
                    textScaler: MediaQuery.of(context).textScaler,
                    textDirection: TextDirection.ltr)
                  ..layout(maxWidth: maxTextLineWidth))
                .size;
            if (attr.embeddedObjectCount > 0) {
              columnWidth = maxTextLineWidth;
            }
            columnWidth = max(columnWidth, size.width + defaultTextPadding);
          default:
        }
        columnWidths[i] = columnWidth;
      }
    }
    final int columnWithPrefix = widget.controller.headingsColumn;
    if (columnWithPrefix < columnWidths.length) {
      columnWidths[columnWithPrefix] += 40;
    }
    return columnWidths;
  }

  Widget? _buildRowPosition(BuildContext context, TableVicinity vicinity) {
    final int rowIndex = vicinity.row - 1;
    final element = widget.part[rowIndex];
    final realRow =
        widget.part.mapFilteredPositionToOriginalPosition(element.position) + 1;
    return Center(
      child: Text('$realRow'),
    );
  }

  TableVicinity _selected() {
    return widget.data.partSelections[widget.partNumber];
  }

  void _onSelectionChanged(TableVicinity position, CellState state) {
    widget.data.partSelections[widget.partNumber] = position;
    if (state != CellState.selected ||
        position.row < 1 ||
        position.column < 1) {
      return;
    }
    if (!widget.hasData || !widget.hasPart) {
      widget.onNewQuillEditor(null);
      return;
    }
    final map = widget.data.columnMapping[widget.partNumber];
    final int columnIndex = map.remap(position.column - 1);
    final int rowIndex = position.row - 1;
    final element = widget.part[rowIndex];
    var value = element.object[columnIndex];
    final datatype = widget.part.type[columnIndex];
    final bool isEditable =
        ((datatype.isEditable && element.isEditable && widget.isEditable) ||
            widget.forceEditable);
    if (value == null &&
        isEditable &&
        datatype.dataType == ReqIfElementTypes.datatypeDefinitionXhtml) {
      value = element.object.appendXhtmlValue(datatype.identifier);
    }
    if (value == null) {
      widget.onNewQuillEditor(null);
      return;
    }
    if (isEditable && value.embeddedObjectCount == 0) {
      switch (value.type) {
        case ReqIfElementTypes.attributeValueXhtml:
          widget.onNewQuillEditor(value);
        default:
          widget.onNewQuillEditor(null);
      }
    }
  }

  Widget? _buildColumnHeader(BuildContext context, dynamic vicinity) {
    if (!widget.hasData || !widget.hasPart) {
      return null;
    }
    final map = widget.data.columnMapping[widget.partNumber];
    final int columnIndex = map.remap(vicinity.column - 1);
    final datatype = widget.part.type[columnIndex];
    final partNumber = widget.partNumber;
    final data = widget.data;
    if (datatype.name != null) {
      return ColumnHeader(
        text: datatype.name!,
        controller: data.partFilterControllers[partNumber][columnIndex],
        showTextInput: widget.filterIsEnabled,
        onChanged: (v) => widget.onNewFilterValue(),
      );
    }
    return null;
  }

  CellContents _wrapWithPrefix(ReqIfDocumentElement element, Widget child,
      CellAttributes? attributes, bool wrap) {
    if (!wrap || element.prefix == null) {
      return CellContents(attribute: attributes, child: child);
    }

    return CellContents(
        attribute: attributes,
        child: Row(
          children: [
            Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.fromLTRB(5, 5, 8, 0),
                child: Text(element.prefix!)),
            child
          ],
        ));
  }

  CellContents? _buildCell(
      BuildContext context, dynamic vicinity, bool selected) {
    if (!widget.hasData || !widget.hasPart) {
      return null;
    }
    final map = widget.data.columnMapping[widget.partNumber];
    final int rowIndex = vicinity.row - 1;
    final int columnIndex = map.remap(vicinity.column - 1);
    final element = widget.part[rowIndex];
    final value = element.object[columnIndex];
    final datatype = widget.part.type[columnIndex];
    CellAttributes? cellAttribute =
        element.type == ReqIfFlatDocumentElementType.heading
            ? CellAttributes.heading
            : null;
    if (value == null) {
      return CellContents(child: null, attribute: cellAttribute);
    }

    final bool wrapWithPrefix =
        widget.controller.headingsColumn == columnIndex &&
            element.type == ReqIfFlatDocumentElementType.heading;
    if (((datatype.isEditable && element.isEditable && widget.isEditable) ||
            widget.forceEditable) &&
        value.embeddedObjectCount == 0) {
      /// marked as editable by document
      switch (value.type) {
        case ReqIfElementTypes.attributeValueEnumeration:
          return CellContents(
              child: _buildEditableEnumList(
                  context, value as ReqIfAttributeValueEnum),
              attribute: cellAttribute);
        case ReqIfElementTypes.attributeValueXhtml:
          value as ReqIfAttributeValueXhtml;
          if (selected) {
            return CellContents(child: _buildQuillEditor());
          }
          return CellContents(
              child: Center(
                  child: XHtmlToWidgetsConverter(
                node: value.node,
                cache: widget.data,
              )),
              attribute: cellAttribute);
        case ReqIfElementTypes.attributeValueString:
          return _wrapWithPrefix(
              element, Text(value.toString()), cellAttribute, wrapWithPrefix);
        case ReqIfElementTypes.attributeValueInteger:
          return _wrapWithPrefix(
              element, Text(value.toString()), cellAttribute, wrapWithPrefix);
        default:
          return null;
      }
    }
    switch (value.type) {
      case ReqIfElementTypes.attributeValueEnumeration:
        return CellContents(
            child: _buildConstEnumList(value as ReqIfAttributeValueEnum),
            attribute: cellAttribute);
      case ReqIfElementTypes.attributeValueString:
        return _wrapWithPrefix(element, SelectableText(value.toString()),
            cellAttribute, wrapWithPrefix);
      case ReqIfElementTypes.attributeValueXhtml:
        return _wrapWithPrefix(
            element,
            Center(
                child: XHtmlToWidgetsConverter(
              node: value.node,
              cache: widget.data,
            )),
            cellAttribute,
            wrapWithPrefix);
      case ReqIfElementTypes.attributeValueInteger:
        return _wrapWithPrefix(
            element, Text(value.toString()), cellAttribute, wrapWithPrefix);
      default:
        return null;
    }
  }

  Widget? _buildConstEnumList(ReqIfAttributeValueEnum value) {
    if (value.length > 1) {
      List<Text> values = [];
      for (int i = 0; i < value.length; ++i) {
        values.add(Text(value.value(i)));
      }
      return Column(children: values);
    } else if (value.length == 1) {
      return Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.all(5),
          child: Text(value.value(0)));
    }
    return null;
  }

  Widget? _buildEditableEnumList(
      BuildContext context, ReqIfAttributeValueEnum value) {
    final cache = _comboBoxDropDownLists[value.column];
    if (cache == null || cache.length != value.validValues.length) {
      throw ReqIfError("internal error: Cache seems to be invalid");
    }
    final textTheme = Theme.of(context).textTheme;
    if (value.length > 0) {
      List<Widget> values = [];
      for (int i = 0; i < value.length; ++i) {
        values.add(DropdownButton<String>(
            items: cache,
            style: textTheme.bodyMedium,
            onChanged: (v) {
              if (v != null && v != value.value(i)) {
                setState(() {
                  value.setValue(i, v);
                  if (mounted) {
                    widget.wasModified();
                  }
                });
              }
            },
            value: value.value(i)));
      }
      if (value.length == 1) {
        return Container(alignment: Alignment.topCenter, child: values.first);
      }
      return Column(children: values);
    }
    return null;
  }
}
