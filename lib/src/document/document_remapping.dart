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

class ColumnMappings {
  final List<int> mappings;
  ColumnMappings(int size) : mappings = [] {
    for (int i = 0; i < size; ++i) {
      mappings.add(i);
    }
  }

  int remap(int displayColumn) {
    if (displayColumn < mappings.length) {
      return mappings[displayColumn];
    }
    return displayColumn;
  }

  int inverse(int internalColumn) {
    final displayColumn = mappings.indexOf(internalColumn);
    if (displayColumn < 0) {
      return internalColumn;
    }
    return displayColumn;
  }

  /// [move] less than zero moves the column to an earlier position
  void moveColumn(int column, int move) {
    moveDataInList<int>(mappings, column, move);
  }

  /// Creates a json fragment as string to serialize the document order.
  String toJsonFragment(int part) {
    StringBuffer rv = StringBuffer('"$part":');
    rv.write(json.encode(mappings));
    return rv.toString();
  }

  /// Reads the [data] from a json object by searching for [part].
  void fromJson(dynamic data, int part) {
    try {
      final key = "$part";
      if (data is Map) {
        if (data.containsKey(key)) {
          final list = data[key];
          if (list is List) {
            if (list.length == mappings.length) {
              for (int i = 0; i < list.length; ++i) {
                mappings[i] = list[i];
                if (mappings.length <= mappings[i]) {
                  throw RangeError.range(mappings[i], 0, mappings.length);
                }
              }
            }
          }
        }
      }
      for (int i = 0; i < mappings.length; ++i) {
        for (int k = i + 1; k < mappings.length; ++k) {
          if (mappings[i] == mappings[k]) {
            // duplicate mappings are invalid
            throw RangeError.range(mappings[i], 0, mappings.length);
          }
        }
      }
    } catch (id) {
      reset();
    }
  }

  bool isNormalOrder() {
    for (int i = 0; i < mappings.length; ++i) {
      if (mappings[i] != i) {
        return false;
      }
    }
    return true;
  }

  bool reset() {
    if (isNormalOrder()) {
      return false;
    }
    for (int i = 0; i < mappings.length; ++i) {
      mappings[i] = i;
    }
    return true;
  }
}
