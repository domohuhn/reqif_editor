// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:convert';

import 'package:reqif_editor/src/document/model/base_sort_list_model.dart';
import 'package:reqif_editor/src/document/model/base_sort_model.dart';
import 'package:reqif_editor/src/document/model/table_model.dart';

/// A model that can swap columns.
class FilterColumnModel extends BaseSortModel {
  final List<bool> _visible;

  FilterColumnModel(super._nextModel)
      : _visible = List.filled(_nextModel.totalColumns, true);

  @override
  DisplayColumn get columns =>
      _visible.fold<int>(0, (int v, a) => a ? v + 1 : v);

  @override
  int mapColumn(DisplayColumn column) {
    int counted = 0;
    for (int i = 0; i < _visible.length; ++i) {
      if (_visible[i]) {
        if (column == counted) {
          return i;
        }
        counted += 1;
      }
    }
    return -1;
  }

  @override
  DisplayColumn inverseMapColumn(int column) {
    if (column >= 0 && column < _visible.length && _visible[column]) {
      int counted = 0;
      for (int i = 0; i < column; ++i) {
        if (_visible[i]) {
          counted += 1;
        }
      }
      return counted;
    }
    return -1;
  }

  /// [move] less than zero moves the column to an earlier position
  void moveColumn(int display, int move) {
    moveDataInList<bool>(_visible, display, move);
  }

  /// Called by child models in case rows or columns are sorted
  @override
  void onColumnMoved(int column, int move) {
    moveColumn(column, move);
    parent?.onColumnMoved(column, move);
  }

  /// Creates a json fragment as string to serialize the document order.
  String toJson() {
    return json.encode(_visible);
  }

  bool get visibilityFilterActive => _visible.any((v) => !v);

  bool resetVisibility() {
    final rv = visibilityFilterActive;
    _visible.fillRange(0, _visible.length, true);
    return rv;
  }

  /// Sets the visibility of [column] to [visible].
  void setVisibility(int column, bool visible) {
    if (column >= 0 && column < _visible.length) {
      if (!visible && _visible[column]) {
        parent?.onColumnRemoved(inverseMapColumn(column));
      }
      final inserted = visible && !_visible[column];
      _visible[column] = visible;
      if (inserted) {
        parent?.onColumnInserted(inverseMapColumn(column));
      }
    }
  }

  /// Gets the visibility of [column].
  bool isVisible(int column) {
    if (column >= 0 && column < _visible.length) {
      return _visible[column];
    }
    return true;
  }

  /// Reads the visibility [data] from a json object by searching for [key].
  void visibilityFromJson(dynamic data, String key) {
    try {
      if (data is Map) {
        if (data.containsKey(key)) {
          final list = data[key];
          if (list is List) {
            if (list.length == _visible.length) {
              for (int i = 0; i < list.length; ++i) {
                _visible[i] = list[i];
              }
            }
          }
        }
      }
    } catch (id) {
      resetVisibility();
    }
  }
}
