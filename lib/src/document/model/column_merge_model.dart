// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/document/model/base_sort_model.dart';
import 'package:reqif_editor/src/document/model/table_model.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart'
    show TableVicinity;

/// A model that can merge two columns.
class ColumnMergeModel extends BaseSortModel {
  bool _mergeActive = false;
  int _mergeSource = -1;
  int _mergeTarget = -1;
  String _mergeSourceColumnName = "";
  String _mergeTargetColumnName = "";

  ColumnMergeModel(super._nextModel);

  bool get mergeActive => _mergeActive;
  set mergeActive(bool v) => setMergeOptions(active: v);

  int get mergeSource => _mergeSource;

  int get mergeTarget => _mergeTarget;

  String get mergeSourceColumnName => _mergeSourceColumnName;
  set mergeSourceColumnName(String v) => setMergeOptions(source: v);
  String get mergeTargetColumnName => _mergeTargetColumnName;
  set mergeTargetColumnName(String v) => setMergeOptions(target: v);

  void setMergeColumnNumbers({bool? active, int? source, int? target}) {
    if (active != null) {
      _mergeActive = active;
    }
    if (source != null) {
      _mergeSource = source;
    }
    if (target != null) {
      _mergeTarget = target;
    }
    _selectWidthSource();
  }

  void setMergeOptions({bool? active, String? source, String? target}) {
    if (active != null) {
      _mergeActive = active;
    }
    if (source != null) {
      _mergeSourceColumnName = source;
    }
    if (target != null) {
      _mergeTargetColumnName = target;
    }
    _selectColumnNumbers();
    _selectWidthSource();
  }

  int _computeNewColumn(int old, int columnToMove, int move) {
    int rv = old;
    int target = columnToMove + move;
    if (old == columnToMove) {
      rv += move;
    } else if (columnToMove < old && target >= old) {
      rv -= 1;
    } else if (columnToMove > old && target <= old) {
      rv += 1;
    }
    return rv;
  }

  /// Called by child models in case rows or columns are sorted
  @override
  void onColumnMoved(int column, int move) {
    // TODO FIX BUG - filter active and swap with invisible row == merging becomes inactive
    _mergeSource = _computeNewColumn(_mergeSource, column, move);
    _mergeTarget = _computeNewColumn(_mergeTarget, column, move);
    parent?.onColumnMoved(column, move);
  }

  bool get mergeActiveAndValid =>
      _mergeActive &&
      _mergeTarget >= 0 &&
      _mergeSource >= 0 &&
      _mergeTarget < super.columns &&
      _mergeSource < super.columns;

  @override
  DisplayColumn get columns {
    if (mergeActiveAndValid) {
      return super.columns - 1;
    }
    return super.columns;
  }

  @override
  int mapColumn(DisplayColumn column) {
    if (mergeActiveAndValid && column >= _mergeTarget) {
      return column + 1;
    }
    return column;
  }

  @override
  DisplayColumn inverseMapColumn(int column) {
    if (mergeActiveAndValid && column > _mergeTarget) {
      return column - 1;
    }
    return column;
  }

  /// Creates a json fragment as string to serialize the parameters.
  String toJson() {
    return '{"active":$_mergeActive,"source":"$_mergeSourceColumnName","target":"$_mergeTargetColumnName"}';
  }

  bool resetMerging() {
    bool rv = _mergeActive;
    _mergeActive = false;
    _mergeSource = -1;
    _mergeTarget = -1;
    _mergeSourceColumnName = "";
    _mergeTargetColumnName = "";
    return rv;
  }

  /// Reads the visibility [data] from a json object.
  void fromJson(dynamic data, String key) {
    bool valuesSet = false;
    if (data is Map && data.containsKey(key)) {
      final filterData = data[key];
      if (filterData.containsKey("active") &&
          filterData.containsKey("source") &&
          filterData.containsKey("target")) {
        _mergeActive = filterData["active"];
        _mergeSourceColumnName = filterData["source"];
        _mergeTargetColumnName = filterData["target"];
        valuesSet = true;
      }
    }
    if (!valuesSet) {
      resetMerging();
    }
    _selectColumnNumbers();
    _selectWidthSource();
  }

  bool _isMergeColumn(DisplayColumn column) {
    return mergeActiveAndValid &&
        ((_mergeSource < _mergeTarget && column == _mergeSource) ||
            (_mergeSource > _mergeTarget && column + 1 == _mergeSource));
  }

  @override
  Cell? operator [](TableVicinity position) {
    if (_isMergeColumn(position.column)) {
      final v1 = super
          .nextModel[TableVicinity(row: position.row, column: _mergeSource)];
      final v2 = super
          .nextModel[TableVicinity(row: position.row, column: _mergeTarget)];
      if (v1 != null) {
        if (v2 != null) {
          v1.extend(v2);
        }
        return v1;
      }
      return v2;
    }
    return super[position];
  }

  @override
  double columnWidth(DisplayColumn column) {
    if (_isMergeColumn(column)) {
      return super.nextModel.columnWidth(_widthSource);
    }
    return super.columnWidth(column);
  }

  @override
  void setColumnWidth(DisplayColumn column, double width) {
    if (_isMergeColumn(column)) {
      return super.nextModel.setColumnWidth(_widthSource, width);
    }
    return super.setColumnWidth(column, width);
  }

  bool _selectedSource = false;
  int get _widthSource => _selectedSource ? _mergeSource : _mergeTarget;

  void _selectColumnNumbers() {
    _mergeSource = -1;
    _mergeTarget = -1;
    for (int i = 0; i < columns; ++i) {
      final cell = super.nextModel[TableVicinity(row: 0, column: i)];
      if (cell != null &&
          cell.content.length == 1 &&
          cell.content.first is String) {
        final name = cell.content.first;
        if (_mergeSourceColumnName == name) {
          _mergeSource = i;
        }
        if (_mergeTargetColumnName == name) {
          _mergeTarget = i;
        }
      }
    }
  }

  void _selectWidthSource() {
    if (!mergeActiveAndValid) {
      return;
    }
    final w1 = super.nextModel.columnWidth(_mergeSource);
    final w2 = super.nextModel.columnWidth(_mergeTarget);
    _selectedSource = w1 > w2;
  }

  @override
  void onColumnInserted(DisplayColumn insert) {
    if (insert <= _mergeSource) {
      _mergeSource += 1;
    }
    if (insert <= _mergeTarget) {
      _mergeTarget += 1;
    }
    parent?.onColumnInserted(insert);
  }

  @override
  void onColumnRemoved(DisplayColumn removed) {
    if (removed <= _mergeSource) {
      _mergeSource -= 1;
    }
    if (removed <= _mergeTarget) {
      _mergeTarget -= 1;
    }
    parent?.onColumnRemoved(removed);
  }
}
