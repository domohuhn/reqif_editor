// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/document/model/final_model.dart';
import 'package:reqif_editor/src/document/model/table_model.dart';
import 'package:reqif_editor/src/reqif/flat_document.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart'
    show TableVicinity;

class ReqIfModel extends FinalModelWithExtends {
  final ReqIfDocumentPart part;
  List<String> columnNames;

  ReqIfModel(this.part, {super.defaultWidth, super.defaultHeight})
      : columnNames = part.columnNames,
        cellSizesInitialized = false,
        super(columns: part.columnCount + 1, rows: part.rowCount + 1);

  Cell? _buildTitleCell(int row, int col) {
    if (row == 0 && col == 0) {
      return null;
    }
    if (row == 0 && col > 0) {
      final int nameIndex = col - 1;
      if (nameIndex >= 0 && nameIndex < columnNames.length) {
        return Cell(row, col, "str", [columnNames[nameIndex]]);
      }
    }
    if (col == 0 && row > 0) {
      final int rowIndex = row - 1;
      if (rowIndex < part.rowCount) {
        final element = part[rowIndex];
        final realRow =
            part.mapFilteredPositionToOriginalPosition(element.position) + 1;
        return Cell(row, col, "str", ["$realRow"]);
      }
    }
    return null;
  }

  /// Returns the data for a row.
  @override
  dynamic getRow(DisplayRow row) {
    final int rowIndex = row - 1;
    if (row <= 0 || rowIndex < 0 || rowIndex >= part.rowCount) {
      return null;
    }
    return part[rowIndex];
  }

  @override
  Cell? operator [](TableVicinity position) {
    if (position.row <= 0 || position.column <= 0) {
      return _buildTitleCell(position.row, position.column);
    }
    final int rowIndex = position.row - 1;
    final int columnIndex = position.column - 1;
    if (rowIndex < part.rowCount && columnIndex < part.columnCount) {
      final element = part[rowIndex];
      var value = element.object[columnIndex];
      final datatype = part.type[columnIndex];
      bool isDefault = false;
      if (value == null &&
          datatype.hasDefaultValue &&
          datatype.defaultValue!.type ==
              ReqIfElementTypes.attributeValueEnumeration) {
        value = datatype.defaultValue;
        isDefault = true;
      }
      if (value == null) {
        return null;
      }
      return Cell(position.row, position.column, datatype, [value],
          matches: false,
          isDefaultValue: isDefault,
          selected: false,
          isEditable: element.isEditable,
          isHeading: element.type == ReqIfFlatDocumentElementType.heading,
          prefix: element.prefix);
    }
    return null;
  }

  /// call this whenever the size of the underlying model changes
  void onSizeChange() {
    cellSizesInitialized = false;
    resize(columns: part.columnCount + 1, rows: part.rowCount + 1);
  }

  @override
  bool cellSizesInitialized;
}
