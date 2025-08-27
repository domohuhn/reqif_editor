// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart'
    show TableVicinity;

/// A simple struct that holds the data for a cell.
class Cell {
  /// The original row (without filtering or sorting)
  int row;

  /// The original column (without filtering or sorting)
  int column;

  /// The type or attributes of the cells content
  dynamic type;

  /// Data stored in the cell.
  ///
  /// It may hold multiple values if one of the models merges
  /// cells or rows.
  List<dynamic> content;

  /// The cells contents are selected.
  bool selected;

  /// Matches a search
  bool matches;

  /// Is a default value
  bool isDefaultValue;

  Cell(this.row, this.column, this.type, this.content,
      {this.selected = false,
      this.matches = false,
      this.isDefaultValue = false});
}

/// Wrapper for an int that encodes the reference system into the type system.
typedef DisplayColumn = int;
typedef DisplayRow = int;

/// Provides an abstract class that models a table document.
///
/// Subclasses can implement features like sorting and filtering
/// by modifying the indexes and row and column counts.
abstract class TableModel {
  /// Returns the number of visible rows in the table.
  DisplayRow get rows;

  /// Returns the number of visible columns in the table.
  DisplayColumn get columns;

  /// Returns the number of rows in the table.
  int get totalRows;

  /// Returns the number of columns in the table.
  int get totalColumns;

  /// Returns the width of the [column]
  double columnWidth(DisplayColumn column);

  /// Sets the [width] of the [column]
  void setColumnWidth(DisplayColumn column, double width);

  /// Returns the height of the [row]
  double rowHeight(DisplayRow row);

  /// Sets the [height] of the [row]
  void setRowHeight(DisplayRow row, double height);

  /// Gets the position of the selected element or null if nothing is selected.
  TableVicinity? get selected;

  /// Sets the position of the selected element.
  set selected(TableVicinity? position);

  /// Returns the contents of the given cell at the given [position],
  /// if there is data in the model.
  Cell? operator [](TableVicinity position);

  /// Returns the real position (without filtering or reordering) of [displayPosition].
  ///
  /// For example, a user might reorder the columns to 2,0,1. So, if we call this method with
  /// column 1, we get 0 as return value. (Using this example, all pairs are 0->2, 1->0, 2->1).
  TableVicinity map(TableVicinity displayPosition);

  /// Returns the display position (with filtering and reordering) of [position].
  ///
  /// For example, a user might reorder the columns to 2,0,1. So, if we call this method with
  /// column 1, we get 0 as return value. (Using this example, all pairs are 0->1, 1->2, 2->0).
  TableVicinity inverseMap(TableVicinity position);

  /// Models can be chained. Use this method to get the base model
  TableModel get baseModel;
}
