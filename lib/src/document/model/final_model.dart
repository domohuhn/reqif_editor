// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/document/model/table_model.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart'
    show TableVicinity;

/// A simple model that serves as end for a model / filter chain.
abstract class FinalModel implements TableModel {
  @override
  TableVicinity? selected;

  @override
  TableModel get baseModel => this;

  @override
  int get totalColumns => columns;

  @override
  int get totalRows => rows;

  @override
  TableVicinity inverseMap(TableVicinity position) {
    return position;
  }

  @override
  TableVicinity map(TableVicinity displayPosition) {
    return displayPosition;
  }
}

/// A simple model that forms the end of a model chain and also holds a list for the width and heights of cells.
abstract class FinalModelWithExtends extends FinalModel {
  List<double> widths;
  List<double> heights;

  FinalModelWithExtends(
      {required int columns,
      required int rows,
      double defaultWidth = 100,
      double defaultHeight = 100})
      : widths = List<double>.filled(columns, defaultWidth),
        heights = List<double>.filled(rows, defaultHeight);

  FinalModelWithExtends.fromLists(
      {required this.widths, required this.heights});

  @override
  DisplayColumn get columns => widths.length;

  @override
  DisplayRow get rows => heights.length;

  @override
  double columnWidth(DisplayColumn column) {
    if (column < widths.length) {
      return widths[column];
    }
    throw RangeError.index(column, widths);
  }

  @override
  void setColumnWidth(DisplayColumn column, double width) {
    if (column < widths.length) {
      widths[column] = width;
    }
  }

  @override
  double rowHeight(DisplayRow row) {
    if (row < heights.length) {
      return heights[row];
    }
    throw RangeError.index(row, heights);
  }

  @override
  void setRowHeight(DisplayRow row, double height) {
    if (row < heights.length) {
      heights[row] = height;
    }
  }
}
