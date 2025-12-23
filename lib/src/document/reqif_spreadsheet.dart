// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show TextInputFormatter, FilteringTextInputFormatter;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:reqif_editor/src/document/column_header.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/document/document_data.dart';
import 'package:reqif_editor/src/document/model/table_model.dart';
import 'package:reqif_editor/src/document/resizable_table_view.dart';
import 'package:reqif_editor/src/reqif/convert_reqif_xhtml_to_widgets.dart';
import 'package:reqif_editor/src/reqif/flat_document.dart';
import 'package:reqif_editor/src/reqif/reqif_attribute_definitions.dart';
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
  final bool searchIsEnabled;

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
      required this.searchIsEnabled,
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
    _numberInputController.dispose();
    super.dispose();
  }

  final FocusNode editorFocusNode = FocusNode();
  bool quillSelected = false;

  Widget _buildQuillEditor() {
    return QuillEditor.basic(
      controller: widget.editorController,
      config: QuillEditorConfig(
        autoFocus: true,
        expands: true,
      ),
      focusNode: editorFocusNode,
    );
  }

  /// Cache for combo boxes
  final List<List<DropdownMenuItem<String>>?> _comboBoxDropDownLists = [];
  final List<DropdownMenuItem<bool>> _comboBoxDropDownBool = [];

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
    _comboBoxDropDownBool.clear();
    _comboBoxDropDownBool
        .add(DropdownMenuItem<bool>(value: true, child: Text("true")));
    _comboBoxDropDownBool
        .add(DropdownMenuItem<bool>(value: false, child: Text("false")));
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
    return ResizableTableView(
        cellBuilder: _buildCell,
        columnHeaderBuilder: _buildColumnHeader,
        initialRowHeights: _estimateInitialRowHeights,
        initialColumnWidths: _estimateInitialColumnWidths,
        onSelectionChanged: _onSelectionChanged,
        model: widget.controller.documents[widget.document]
            .partModels[widget.partNumber],
        selection: _selected,
        rowPositionBuilder: _buildRowPosition,
        selectAble: !quillSelected,
        searchPosition: () {
          if (widget.hasPart && widget.searchIsEnabled) {
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
    return _rowHeights;
  }

  static const double defaultColumnWidth = 120;
  static const double defaultLetterWidth = 8.5;
  static const double defaultTextPadding = 10;
  static const double comboBoxLetterWidth = 7.5;
  static const double comboBoxPadding = 54;

  static const double maxTextLineWidth = 600;

  List<double> _columnWidths = [];
  List<double> _rowHeights = [];

  /// The width of the first column. This column is fixed and contains the line number.
  static const double _rowNumberIndicatorWidth = 64;

  /// The height of the first row. This row is fixed and contains the headings.
  /// Only relevant if the user did not provide a builder for the column headers.
  static const double _columnHeaderHeight = 72;

  void _estimateInitialColumnWidthAndHeight() {
    List<double> columnWidths = [];
    List<double> rowHeights = [];
    rowHeights.add(_columnHeaderHeight);
    for (int i = 0; i < widget.part.columnCount; ++i) {
      columnWidths.add(defaultColumnWidth);
    }
    for (final element in widget.part.elements) {
      double rowHeight = defaultRowHeight;
      final bool rowEditable = element.isEditable && widget.isEditable;
      for (int i = 0; i < widget.part.columnCount; ++i) {
        final column = i;
        final attr = element.object.valueOrDefault(column);
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
                rowHeight = max(rowHeight, attr.length * defaultComboBoxHeight);
              } else {
                columnWidth =
                    max(columnWidth, text.length * defaultLetterWidth);
                rowHeight = max(rowHeight, attr.length * defaultLineHeight);
              }
            }
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
            var currentHeight = size.height + defaultTextPadding;
            if (attr.embeddedObjectCount > 0) {
              currentHeight += columnWidth * attr.embeddedObjectCount;
            }
            if (attr.hasList) {
              currentHeight *= 1.2;
            }
            columnWidth = max(columnWidth, size.width + defaultTextPadding);
            rowHeight = max(rowHeight, currentHeight);
          default:
            final text = attr.toString();
            final Size size = (TextPainter(
                    text: TextSpan(text: text),
                    textScaler: MediaQuery.of(context).textScaler,
                    textDirection: TextDirection.ltr)
                  ..layout(maxWidth: maxTextLineWidth))
                .size;
            columnWidth = max(columnWidth, size.width + defaultTextPadding);
            rowHeight = max(rowHeight, size.height + defaultTextPadding);
        }
        columnWidths[i] = columnWidth;
      }
      rowHeights.add(rowHeight * 1.1);
    }
    columnWidths.insert(0, _rowNumberIndicatorWidth);
    final int columnWithPrefix = widget.controller.headingsColumn + 1;
    if (columnWithPrefix < columnWidths.length) {
      columnWidths[columnWithPrefix] += 40;
    }
    _columnWidths = columnWidths;
    _rowHeights = rowHeights;
  }

  List<double> _estimateInitialColumnWidths() {
    _estimateInitialColumnWidthAndHeight();
    return _columnWidths;
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

  void _onQuillEditorChange(dynamic node) {
    final nextNeedsEditor = node != null;
    if (nextNeedsEditor != quillSelected) {
      widget.controller.setRestoreScrollPositions(true);
    }
    quillSelected = nextNeedsEditor;
    widget.onNewQuillEditor(node);
  }

  bool _editableIntegerWasSelected = false;
  ReqIfAttributeValueInteger? _selectedIntegerValue;

  bool _editableRealWasSelected = false;
  ReqIfAttributeValueReal? _selectedRealValue;
  final TextEditingController _numberInputController = TextEditingController();

  void _updateIntegerValue() {
    if (_editableIntegerWasSelected &&
        _selectedIntegerValue != null &&
        _numberInputController.text != _selectedIntegerValue!.valueString) {
      _selectedIntegerValue!.valueString = _numberInputController.text;
      if (mounted) {
        widget.wasModified();
      }
    }
  }

  void _updateRealValue() {
    if (_editableRealWasSelected &&
        _selectedRealValue != null &&
        _numberInputController.text != _selectedRealValue!.valueString) {
      _selectedRealValue!.valueString = _numberInputController.text;
      if (mounted) {
        widget.wasModified();
      }
    }
  }

  void _onSelectionChanged(TableVicinity position, CellState state) {
    if (!widget.hasData || !widget.hasPart) {
      return;
    }
    widget.controller.setRestoreScrollPositions(false);
    if (widget.data.partSelections[widget.partNumber] == position) {
      widget.data.partSelections[widget.partNumber] =
          const TableVicinity(column: -1, row: -1);
      _onQuillEditorChange(null);
      return;
    }
    widget.data.partSelections[widget.partNumber] = position;
    if (state != CellState.selected ||
        position.row < 1 ||
        position.column < 1) {
      _onQuillEditorChange(null);
      return;
    }
    final model = widget.data.partModels[widget.partNumber];
    final int columnIndex = model.map(position).column - 1;
    final int rowIndex = position.row - 1;
    final element = widget.part[rowIndex];
    var value = element.object[columnIndex];
    final datatype = widget.part.type[columnIndex];
    final bool isEditable =
        ((datatype.isEditable && element.isEditable && widget.isEditable) ||
            widget.forceEditable);
    _updateIntegerValue();
    _selectedIntegerValue = null;
    _editableIntegerWasSelected = false;
    if (value != null &&
        isEditable &&
        value.type == ReqIfElementTypes.attributeValueInteger) {
      value as ReqIfAttributeValueInteger;
      _numberInputController.text = value.valueString;
      _editableIntegerWasSelected = true;
      _selectedIntegerValue = value;
    }
    _updateRealValue();
    _selectedRealValue = null;
    _editableRealWasSelected = false;
    if (value != null &&
        isEditable &&
        value.type == ReqIfElementTypes.attributeValueReal) {
      value as ReqIfAttributeValueReal;
      _numberInputController.text = value.valueString;
      _editableRealWasSelected = true;
      _selectedRealValue = value;
    }
    if (value == null &&
        isEditable &&
        datatype.dataType == ReqIfElementTypes.datatypeDefinitionXhtml) {
      value = element.object.appendXhtmlValue(datatype.identifier);
    }

    if (value == null ||
        !isEditable ||
        value.embeddedObjectCount != 0 ||
        value.type != ReqIfElementTypes.attributeValueXhtml) {
      _onQuillEditorChange(null);
      return;
    }
    _onQuillEditorChange(value);
  }

  Widget? _buildColumnHeader(BuildContext context, dynamic vicinity) {
    if (!widget.hasData || !widget.hasPart) {
      return null;
    }
    final model = widget.data.partModels[widget.partNumber];
    final int columnIndex = model.map(vicinity).column - 1;
    if (columnIndex < 0 || widget.part.type.attributeCount < columnIndex) {
      return null;
    }
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

  CellContents _wrapWithPrefix(
      String? prefix, Widget child, CellAttributes? attributes, bool wrap) {
    if (!wrap || prefix == null) {
      return CellContents(
          attribute: attributes,
          child: Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
              child: child));
    }

    return CellContents(
        attribute: attributes,
        child: Row(
          children: [
            Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.fromLTRB(5, 5, 8, 0),
                child: Text(prefix)),
            child
          ],
        ));
  }

  CellAttributes? _getCellAttributes(Cell content) {
    if (content.isDefaultValue) {
      return CellAttributes.defaultValue;
    }
    if (content.isHeading) {
      return CellAttributes.heading;
    }
    return null;
  }

  CellContents? _buildCell(
      BuildContext context, TableVicinity vicinity, bool selected) {
    if (!widget.hasData || !widget.hasPart) {
      return null;
    }
    final model = widget.data.partModels[widget.partNumber];
    final cellContent = model[vicinity];
    if (cellContent == null || cellContent.content.isEmpty) {
      final element = model.getRow(vicinity.row);
      if (element is ReqIfDocumentElement &&
          element.type == ReqIfFlatDocumentElementType.heading) {
        return CellContents(child: null, attribute: CellAttributes.heading);
      } else {
        return null;
      }
    }
    var type = cellContent.type;
    if (type is! ReqIfAttributeDefinition) {
      return null;
    }

    CellAttributes? cellAttribute = _getCellAttributes(cellContent);
    bool wrapWithPrefix =
        widget.controller.headingsColumn == (cellContent.column - 1) &&
            cellContent.isHeading;

    final bool isEditable =
        ((type.isEditable && cellContent.isEditable && widget.isEditable) ||
                widget.forceEditable) &&
            cellContent.content.length == 1 &&
            cellContent.content.first is ReqIfAttributeValue &&
            cellContent.content.first.embeddedObjectCount == 0;

    if (isEditable) {
      return _buildEditableCell(cellContent, model, vicinity, context,
          cellAttribute, selected, wrapWithPrefix);
    }
    return _buildConstantCell(cellContent, wrapWithPrefix, cellAttribute);
  }

  CellContents? _buildConstantCell(
      Cell cellContent, bool wrapWithPrefix, CellAttributes? cellAttribute) {
    List<Widget> children = [];
    for (final content in cellContent.content) {
      if (content == null || content is! ReqIfAttributeValue) {
        continue;
      }
      final value = content;
      switch (value.type) {
        case ReqIfElementTypes.attributeValueEnumeration:
          Widget? tmp = _buildConstEnumList(value as ReqIfAttributeValueEnum);
          if (tmp != null) {
            children.add(tmp);
            wrapWithPrefix = false;
          }
        case ReqIfElementTypes.attributeValueXhtml:
          children.add(Center(
              child: XHtmlToWidgetsConverter(
            node: value.node,
            cache: widget.data,
          )));
        default:
          children.add(Center(child: Text(value.toString())));
      }
    }
    if (children.length == 1) {
      return _wrapWithPrefix(
          cellContent.prefix, children.first, cellAttribute, wrapWithPrefix);
    } else if (children.isEmpty) {
      return null;
    } else {
      return _wrapWithPrefix(
          cellContent.prefix,
          Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children),
          cellAttribute,
          wrapWithPrefix);
    }
  }

  CellContents? _buildEditableCell(
      Cell cellContent,
      TableModel model,
      TableVicinity vicinity,
      BuildContext context,
      CellAttributes? cellAttribute,
      bool selected,
      bool wrapWithPrefix) {
    final value = cellContent.content.first as ReqIfAttributeValue;

    /// marked as editable by document
    switch (value.type) {
      case ReqIfElementTypes.attributeValueEnumeration:
        final element = model.getRow(vicinity.row);
        if (element is ReqIfDocumentElement) {
          return CellContents(
              child: _buildEditableEnumList(
                  context,
                  value as ReqIfAttributeValueEnum,
                  element,
                  cellAttribute == CellAttributes.defaultValue),
              attribute: cellAttribute);
        } else {
          return null;
        }
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
      case ReqIfElementTypes.attributeValueBoolean:
        value as ReqIfAttributeValueBool;
        if (selected) {
          return CellContents(child: _buildEditableBool(context, value));
        }
        return _wrapWithPrefix(
            cellContent.prefix,
            Center(child: Text(value.toString())),
            cellAttribute,
            wrapWithPrefix);
      case ReqIfElementTypes.attributeValueInteger:
        value as ReqIfAttributeValueInteger;
        if (selected) {
          return CellContents(
              child: Center(
                  child: TextField(
            keyboardType: TextInputType.number,
            controller: _numberInputController,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^[+-]?[0123456789]*'))
            ],
            onChanged: (v) {
              if (v != value.valueString) {
                _updateIntegerValue();
              }
            },
          )));
        }
        return _wrapWithPrefix(
            cellContent.prefix,
            Center(child: Text(value.toString())),
            cellAttribute,
            wrapWithPrefix);
      case ReqIfElementTypes.attributeValueReal:
        value as ReqIfAttributeValueReal;
        if (selected) {
          return CellContents(
              child: Center(
                  child: TextField(
            keyboardType: TextInputType.number,
            controller: _numberInputController,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(
                  RegExp(r'^[+-]?[0123456789]*\.?[0123456789]*'))
            ],
            onChanged: (v) {
              if (v != value.valueString) {
                _updateRealValue();
              }
            },
          )));
        }
        return _wrapWithPrefix(
            cellContent.prefix,
            Center(child: Text(value.toString())),
            cellAttribute,
            wrapWithPrefix);
      default:
        return _wrapWithPrefix(
            cellContent.prefix,
            Center(child: Text(value.toString())),
            cellAttribute,
            wrapWithPrefix);
    }
  }

  Widget? _buildConstEnumList(ReqIfAttributeValueEnum value) {
    if (value.length > 1) {
      List<Text> values = [];
      for (int i = 0; i < value.length; ++i) {
        values.add(Text(value.value(i)));
      }
      return Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.all(5),
          child: Column(children: values));
    } else if (value.length == 1) {
      return Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.all(5),
          child: Text(value.value(0)));
    }
    return null;
  }

  Widget? _buildEditableEnumList(
      BuildContext context,
      ReqIfAttributeValueEnum value,
      ReqIfDocumentElement element,
      bool isDefault) {
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
                if (isDefault) {
                  var newValue =
                      element.object.appendEnumValue(value.definitionId);
                  newValue.setValue(i, v);
                } else {
                  value.setValue(i, v);
                }
                if (mounted) {
                  widget.wasModified();
                }
              }
              final focus = FocusScope.of(context);
              focus.unfocus();
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

  Widget? _buildEditableBool(
      BuildContext context, ReqIfAttributeValueBool value) {
    final cache = _comboBoxDropDownBool;
    if (cache.length != 2) {
      throw ReqIfError("internal error: Cache seems to be invalid");
    }
    final textTheme = Theme.of(context).textTheme;
    final button = DropdownButton<bool>(
        items: cache,
        style: textTheme.bodyMedium,
        onChanged: (v) {
          if (v != null && v != value.value()) {
            // TODO default values
            value.setValue(v);
            if (mounted) {
              widget.wasModified();
            }
          }
          final focus = FocusScope.of(context);
          focus.unfocus();
        },
        value: value.value());
    return Container(alignment: Alignment.topCenter, child: button);
  }
}
