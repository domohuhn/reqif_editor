// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/document/model/base_sort_list_model.dart';
import 'package:reqif_editor/src/document/model/table_model.dart';

/// A model that can swap columns.
class SortRowModel extends SortFromListModel {
  SortRowModel(TableModel next)
      : super(next, List.generate(next.totalRows, (i) => i));

  @override
  int mapRow(DisplayRow row) {
    return baseMap(row);
  }

  @override
  DisplayRow inverseMapRow(int row) {
    return inverseBaseMap(row);
  }

  /// [move] less than zero moves the column to an earlier position
  void moveRow(int column, int move) {
    moveInMap(column, move);
    parent?.onRowMoved(column, move);
  }
}
