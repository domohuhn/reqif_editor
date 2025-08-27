// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/document/model/base_sort_list_model.dart';
import 'package:reqif_editor/src/document/model/table_model.dart';

/// A model that can swap columns.
class SortColumnModel extends SortFromListModel {
  SortColumnModel(TableModel next)
      : super(next, List.generate(next.totalColumns, (i) => i));

  @override
  int mapColumn(DisplayColumn column) {
    return baseMap(column);
  }

  @override
  DisplayColumn inverseMapColumn(int column) {
    return inverseBaseMap(column);
  }

  /// [move] less than zero moves the column to an earlier position
  void moveColumn(int column, int move) {
    moveInMap(column, move);
    parent?.onColumnMoved(column, move);
  }
}
