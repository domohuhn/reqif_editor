// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:convert';
import 'dart:math';

void moveDataInList<T>(List<T> data, int index, int move) {
  if (index < 0 || index >= data.length || move == 0) {
    return;
  }
  final target = max(min(index + move, data.length - 1), 0);
  if (move < 0) {
    for (int i = index; i > target; --i) {
      T tmp = data[i];
      data[i] = data[i - 1];
      data[i - 1] = tmp;
    }
  } else {
    for (int i = index; i < target; i++) {
      T tmp = data[i];
      data[i] = data[i + 1];
      data[i + 1] = tmp;
    }
  }
}

class ColumnData {
  int column;
  bool visible;
  ColumnData(this.column, this.visible);
}

class ColumnMappings {
  final List<ColumnData> _mappings;
  ColumnMappings(int size) : _mappings = [] {
    for (int i = 0; i < size; ++i) {
      _mappings.add(ColumnData(i, true));
    }
  }

  int remap(int displayColumn) {
    if (displayColumn >= 0 && displayColumn < _mappings.length) {
      return _mappings[displayColumn].column;
    }
    return displayColumn;
  }

  int inverse(int internalColumn) {
    final displayColumn =
        _mappings.indexWhere((v) => v.column == internalColumn);
    if (displayColumn < 0) {
      return internalColumn;
    }
    return displayColumn;
  }

  int remapWithVisibility(int displayColumn) {
    final maxIteration = _mappings.length;
    if (displayColumn >= 0 && displayColumn < maxIteration) {
      int visibleCount = 0;
      for (int i = 0; i < maxIteration; ++i) {
        if (_mappings[i].visible) {
          if (visibleCount == displayColumn) {
            return _mappings[i].column;
          }
          visibleCount++;
        }
      }
    }
    return displayColumn;
  }

  int inverseWithVisibility(int internalColumn) {
    final displayColumn =
        _mappings.indexWhere((v) => v.column == internalColumn);
    if (displayColumn < 0) {
      return internalColumn;
    }
    return displayColumn;
  }

  /// [move] less than zero moves the column to an earlier position
  void moveColumn(int column, int move) {
    moveDataInList<ColumnData>(_mappings, column, move);
  }

  /// Creates a json fragment as string to serialize the document order.
  String orderToJsonFragment(int part) {
    StringBuffer rv = StringBuffer('"$part":');
    List<int> order = [];
    for (final val in _mappings) {
      order.add(val.column);
    }
    rv.write(json.encode(order));
    return rv.toString();
  }

  /// Reads the column order [data] from a json object by searching for [part].
  void orderFromJson(dynamic data, int part) {
    try {
      final key = "$part";
      if (data is Map) {
        if (data.containsKey(key)) {
          final list = data[key];
          if (list is List) {
            if (list.length == _mappings.length) {
              for (int i = 0; i < list.length; ++i) {
                _mappings[i].column = list[i];
                if (_mappings.length <= _mappings[i].column) {
                  throw RangeError.range(
                      _mappings[i].column, 0, _mappings.length);
                }
              }
            }
          }
        }
      }
      for (int i = 0; i < _mappings.length; ++i) {
        for (int k = i + 1; k < _mappings.length; ++k) {
          if (_mappings[i].column == _mappings[k].column) {
            // duplicate _mappings are invalid
            throw RangeError.range(_mappings[i].column, 0, _mappings.length);
          }
        }
      }
    } catch (id) {
      resetOrder();
    }
  }

  bool isNormalOrder() {
    for (int i = 0; i < _mappings.length; ++i) {
      if (_mappings[i].column != i) {
        return false;
      }
    }
    return true;
  }

  bool resetOrder() {
    if (isNormalOrder()) {
      return false;
    }
    for (int i = 0; i < _mappings.length; ++i) {
      _mappings[i].column = i;
    }
    return true;
  }

  int visibleColumnCount() {
    return _mappings.fold<int>(0, (int v, a) => a.visible ? v + 1 : v);
  }

  bool visibilityFilterActive() {
    return visibleColumnCount() < _mappings.length;
  }

  bool resetVisibility() {
    final rv = visibilityFilterActive();
    for (int i = 0; i < _mappings.length; ++i) {
      _mappings[i].visible = true;
    }
    return rv;
  }

  /// Sets the visibility of [column] to [visible].
  void setVisibility(int column, bool visible) {
    if (column >= 0 && column < _mappings.length) {
      _mappings[column].visible = visible;
    }
  }

  /// Gets the visibility of [column].
  bool isVisible(int column) {
    if (column >= 0 && column < _mappings.length) {
      return _mappings[column].visible;
    }
    return true;
  }

  /// Creates a json fragment as string to serialize the column visibility.
  String visibilityToJsonFragment(int part) {
    StringBuffer rv = StringBuffer('"$part":');
    List<bool> visible = [];
    for (final val in _mappings) {
      visible.add(val.visible);
    }
    rv.write(json.encode(visible));
    return rv.toString();
  }

  /// Reads the visibility [data] from a json object by searching for [part].
  void visibilityFromJson(dynamic data, int part) {
    try {
      final key = "$part";
      if (data is Map) {
        if (data.containsKey(key)) {
          final list = data[key];
          if (list is List) {
            if (list.length == _mappings.length) {
              for (int i = 0; i < list.length; ++i) {
                _mappings[i].visible = list[i];
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
