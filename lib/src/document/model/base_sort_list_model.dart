// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:convert';
import 'dart:math';

import 'package:reqif_editor/src/document/model/base_sort_model.dart';

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

/// A model that can swap columns.
abstract class SortFromListModel extends BaseSortModel {
  final List<int> _map;

  SortFromListModel(super.nextModel, this._map);

  int baseMap(int display) {
    if (display >= 0 && display < _map.length) {
      return _map[display];
    }
    return -1;
  }

  int inverseBaseMap(int internal) {
    final display = _map.indexWhere((v) => v == internal);
    return display < 0 ? -1 : display;
  }

  /// [move] less than zero moves the column to an earlier position
  void moveInMap(int display, int move) {
    moveDataInList<int>(_map, display, move);
  }

  /// Creates a json fragment as string to serialize the document order.
  String toJson() {
    return json.encode(_map);
  }

  /// Reads the column order [data] from a json object by searching for [key].
  void fromJson(dynamic data, String key) {
    try {
      if (data is Map) {
        if (data.containsKey(key)) {
          final list = data[key];
          if (list is List) {
            if (list.length == _map.length) {
              for (int i = 0; i < list.length; ++i) {
                _map[i] = list[i];
                if (_map.length <= _map[i]) {
                  throw RangeError.range(_map[i], 0, _map.length);
                }
              }
            }
          }
        }
      }
      for (int i = 0; i < _map.length; ++i) {
        for (int k = i + 1; k < _map.length; ++k) {
          if (_map[i] == _map[k]) {
            // duplicate _mappings are invalid
            throw RangeError.range(_map[i], 0, _map.length);
          }
        }
      }
    } catch (id) {
      resetOrder();
    }
  }

  bool isNormalOrder() {
    for (int i = 0; i < _map.length; ++i) {
      if (_map[i] != i) {
        return false;
      }
    }
    return true;
  }

  bool resetOrder() {
    if (isNormalOrder()) {
      return false;
    }
    for (int i = 0; i < _map.length; ++i) {
      _map[i] = i;
    }
    return true;
  }
}
