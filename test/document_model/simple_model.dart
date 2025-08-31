// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/document/model/final_model.dart';
import 'package:reqif_editor/src/document/model/table_model.dart'
    show Cell, DisplayRow;
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart'
    show TableVicinity;

/// A simple model used for the tests of the sorting and filtering models.
class SimpleModel extends FinalModelWithExtends {
  SimpleModel(int cols, int rows)
      : cellSizesInitialized = false,
        super.fromLists(
            widths: List.generate(cols, (i) => 50.0 * (i + 1)),
            heights: List.generate(rows, (i) => 50.0 * i + 25.0));

  @override
  Cell? operator [](TableVicinity position) {
    if (position.column < columns && position.row < rows) {
      return Cell(position.row, position.column, "type", ["$position"]);
    }
    return null;
  }

  @override
  bool cellSizesInitialized;

  @override
  getRow(DisplayRow row) {
    throw UnimplementedError();
  }
}
