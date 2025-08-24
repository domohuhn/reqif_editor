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
  int original = 0;
  int mergeTarget = 0;
  bool visible = true;
  bool merge = false;
}

// requirements:
// can reorder columns
// provides column count (+merges)
// holds column widths and heights
// provides reordered random access to widths and heights
// can compute widths and heights
// can create the widgets and merge cols

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
}
