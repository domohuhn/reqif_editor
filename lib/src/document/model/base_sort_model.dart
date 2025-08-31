// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/document/model/table_model.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart'
    show TableVicinity;

/// A model that can swap rows and columns.
class BaseSortModel implements TableModel {
  final TableModel _nextModel;
  BaseSortModel? parent;
  BaseSortModel(this._nextModel) {
    if (_nextModel is BaseSortModel) {
      _nextModel.setParent(this);
    }
  }

  // New methods:
  void setParent(BaseSortModel? base) {
    parent = base;
  }

  /// Maps a column from the display coordinates to the real model coordinates
  int mapColumn(DisplayColumn column) => column;

  /// Maps a row from the display coordinates to the real model coordinates
  int mapRow(DisplayRow row) => row;

  /// Maps a row from the display coordinates to the real model coordinates
  DisplayColumn inverseMapColumn(int column) => column;
  DisplayRow inverseMapRow(int row) => row;

  /// Called by child models in case rows or columns are sorted
  void onRowMoved(int row, int move) {}

  /// Called by child models in case rows or columns are sorted
  void onColumnMoved(int column, int move) {}

  // -----------------------------
  // From here on: methods that can be reused
  // by deriving models.
  // -----------------------------

  /// Returns the data for a row.
  @override
  dynamic getRow(DisplayRow row) => _nextModel.getRow(mapRow(row));

  @override
  DisplayColumn get columns => _nextModel.columns;

  @override
  DisplayRow get rows => _nextModel.rows;

  @override
  int get totalRows => _nextModel.totalRows;

  @override
  int get totalColumns => _nextModel.totalColumns;

  @override
  bool get cellSizesInitialized => _nextModel.cellSizesInitialized;

  @override
  set cellSizesInitialized(bool v) => _nextModel.cellSizesInitialized = v;

  @override
  Cell? operator [](TableVicinity position) {
    return _nextModel[mapOneStep(position)];
  }

  @override
  TableModel get baseModel {
    return _nextModel.baseModel;
  }

  @override
  double columnWidth(DisplayColumn column) {
    return _nextModel.columnWidth(mapColumn(column));
  }

  @override
  double rowHeight(DisplayRow row) {
    return _nextModel.rowHeight(mapRow(row));
  }

  @override
  void setColumnWidth(DisplayColumn column, double width) {
    _nextModel.setColumnWidth(mapColumn(column), width);
  }

  @override
  void setRowHeight(DisplayRow row, double height) {
    _nextModel.setRowHeight(mapRow(row), height);
  }

  /// Sets the [widths] of all columns without applying any sorting or filtering.
  @override
  void setAllColumnWidthsWithoutMap(List<double> widths) =>
      _nextModel.setAllColumnWidthsWithoutMap(widths);

  /// Sets the [heights] of all rows without applying any sorting or filtering.
  @override
  void setAllRowHeightsWithoutMap(List<double> heights) =>
      _nextModel.setAllRowHeightsWithoutMap(heights);

  TableVicinity mapOneStep(TableVicinity displayPosition) => TableVicinity(
      row: mapRow(displayPosition.row),
      column: mapColumn(displayPosition.column));
  TableVicinity inverseMapOneStep(TableVicinity position) => TableVicinity(
      row: inverseMapRow(position.row),
      column: inverseMapColumn(position.column));

  @override
  TableVicinity map(TableVicinity displayPosition) =>
      _nextModel.map(mapOneStep(displayPosition));

  @override
  TableVicinity inverseMap(TableVicinity position) =>
      inverseMapOneStep(_nextModel.inverseMap(position));

  @override
  TableVicinity? get selected {
    final tmp = _nextModel.selected;
    if (tmp == null) {
      return tmp;
    }
    return inverseMapOneStep(tmp);
  }

  @override
  set selected(TableVicinity? position) {
    if (position == null) {
      _nextModel.selected = position;
    } else {
      _nextModel.selected = mapOneStep(position);
    }
  }
}
