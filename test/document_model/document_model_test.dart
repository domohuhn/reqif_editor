// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reqif_editor/src/document/model/column_merge_model.dart'
    show ColumnMergeModel;
import 'package:reqif_editor/src/document/model/filter_column_model.dart';
import 'package:reqif_editor/src/document/model/sort_column_model.dart';
import 'package:reqif_editor/src/document/model/sort_row_model.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'simple_model.dart';

void main() {
  final simpleModel = SimpleModel(5, 10);
  group('Simple models', () {
    test("Simple model", () {
      expect(simpleModel.columns, 5);
      expect(simpleModel.rows, 10);
      for (int c = 0; c < simpleModel.columns; c++) {
        for (int r = 0; r < simpleModel.rows; r++) {
          final position = TableVicinity(row: r, column: c);
          final val = simpleModel[position];
          expect(val == null, false);
          expect(val!.column, c);
          expect(val.row, r);
          expect(simpleModel.map(position), position);
          expect(simpleModel.inverseMap(position), position);
        }
      }
    });
  });

  group('sorting models', () {
    test("Column model - serialize", () {
      final columnModel = SortColumnModel(simpleModel);
      expect(columnModel.toJson(), "[0,1,2,3,4]");
      expect(columnModel.isNormalOrder(), true);
      columnModel.moveColumn(2, 1);
      expect(columnModel.toJson(), "[0,1,3,2,4]");
      expect(columnModel.isNormalOrder(), false);

      final position = TableVicinity(column: 2, row: 1);
      final result = TableVicinity(column: 3, row: 1);
      expect(columnModel.map(position), result);

      columnModel.resetOrder();
      expect(columnModel.toJson(), "[0,1,2,3,4]");
      expect(columnModel.isNormalOrder(), true);
    });

    test("Column model - deserialize", () {
      final order = SortColumnModel(simpleModel);
      final input =
          '{"1":[0,1,2,3,4],"2":["0"],"0":[4,3,2,1,0],"4":[0,1,2,3,3],"3":[0,1,2,3,"a"],"5":[0,1,2,3,5]}';
      final data = jsonDecode(input);

      order.fromJson(data, "0");
      for (int i = 0; i < 5; ++i) {
        expect(order.mapColumn(i), 4 - i);
        expect(order.inverseMapColumn(4 - i), i);
        final position = TableVicinity(column: i, row: 1);
        final result = TableVicinity(column: 4 - i, row: 1);
        expect(order.map(position), result);
        expect(order.inverseMap(result), position);
        expect(order.columnWidth(i), 50.0 * (5 - i));
        expect(order.rowHeight(i), 50.0 * i + 25);
      }

      for (int i = 1; i < 6; ++i) {
        order.fromJson(data, "$i");
        for (int i = 0; i < 5; ++i) {
          expect(order.mapColumn(i), i, reason: "$i failed");
        }
      }
    });

    test("row model - serialize", () {
      final columnModel = SortRowModel(simpleModel);
      expect(columnModel.toJson(), "[0,1,2,3,4,5,6,7,8,9]");
      expect(columnModel.isNormalOrder(), true);
      columnModel.moveRow(2, 1);
      expect(columnModel.toJson(), "[0,1,3,2,4,5,6,7,8,9]");
      expect(columnModel.isNormalOrder(), false);
      columnModel.resetOrder();
      expect(columnModel.toJson(), "[0,1,2,3,4,5,6,7,8,9]");
      expect(columnModel.isNormalOrder(), true);
    });

    test("row model - deserialize", () {
      final order = SortRowModel(simpleModel);
      final input =
          '{"1":[0,1,2,3,4,5,6,7,8,9],"2":["0"],"0":[9,8,7,6,5,4,3,2,1,0],"4":[0,1,2,3,3,5,6,7,8,9],"3":[0,1,2,3,"a",5,6,7,8,9],"5":[0,1,2,3,10,5,6,7,8,9]}';
      final data = jsonDecode(input);

      order.fromJson(data, "0");
      for (int i = 0; i < 10; ++i) {
        expect(order.mapRow(i), 9 - i);
        expect(order.inverseMapRow(9 - i), i);
        final position = TableVicinity(column: 1, row: i);
        final result = TableVicinity(column: 1, row: 9 - i);
        expect(order.map(position), result);
        expect(order.inverseMap(result), position);
        expect(order.rowHeight(i), 50.0 * (9 - i) + 25);
      }

      for (int i = 1; i < 6; ++i) {
        order.fromJson(data, "$i");
        for (int i = 0; i < 10; ++i) {
          expect(order.mapRow(i), i, reason: "$i failed");
        }
      }
    });
  });

  group("filter models", () {
    test('serialize visibility - one part', () {
      final model = FilterColumnModel(simpleModel);
      expect(model.toJson(), '[true,true,true,true,true]');
      expect(model.columns, 5);
      model.setVisibility(0, false);
      expect(model.columns, 4);
      model.setVisibility(3, false);
      expect(model.columns, 3);
      expect(model.toJson(), '[false,true,true,false,true]');

      model.resetVisibility();
      expect(model.columns, 5);
      expect(model.toJson(), '[true,true,true,true,true]');
    });

    test('deserialize visibility - one part', () {
      final model = FilterColumnModel(simpleModel);
      final input =
          '{"0":[false,true,true,false,false],"1":[false,true,false,false,false],"2":[false,false,false,false,false],"3":[true,true,true,true,true],"4":[true],"5":[0,1,1,1,1]}';

      final data = jsonDecode(input);
      model.visibilityFromJson(data, "0");
      expect(model.columns, 2);
      model.visibilityFromJson(data, "1");
      expect(model.columns, 1);
      model.visibilityFromJson(data, "2");
      expect(model.columns, 0);

      for (int i = 3; i < 6; ++i) {
        model.visibilityFromJson(data, "$i");
        expect(model.columns, 5);
      }
    });

    test("Column filter - map", () {
      final model = FilterColumnModel(simpleModel);
      model.setVisibility(1, false);
      model.setVisibility(2, false);
      model.setVisibility(3, false);
      expect(model.mapColumn(0), 0);
      expect(model.mapColumn(1), 4);

      expect(model.inverseMapColumn(0), 0);
      expect(model.inverseMapColumn(1), -1);
      expect(model.inverseMapColumn(2), -1);
      expect(model.inverseMapColumn(3), -1);
      expect(model.inverseMapColumn(4), 1);

      final v1 = TableVicinity(column: 0, row: 1);
      final r1 = TableVicinity(column: 0, row: 1);
      expect(model.map(v1), r1);
      expect(model.inverseMap(r1), v1);

      final v2 = TableVicinity(column: 1, row: 1);
      final r2 = TableVicinity(column: 4, row: 1);
      expect(model.map(v2), r2);
      expect(model.inverseMap(r2), v2);
    });

    test("Column filter - get", () {
      final model = FilterColumnModel(simpleModel);
      model.setVisibility(1, false);
      model.setVisibility(2, false);
      model.setVisibility(3, false);
      final p1 = TableVicinity(column: 0, row: 1);
      final p2 = TableVicinity(column: 1, row: 1);
      final v1 = model[p1];
      final v2 = model[p2];

      expect(v1!.column, 0);
      expect(v2!.column, 4);
    });
  });

  group("filter and sort models", () {
    test("set order first", () {
      final order = SortColumnModel(simpleModel);
      final model = FilterColumnModel(order);

      final input =
          '{"1":[0,1,2,3,4],"2":["0"],"0":[4,3,2,1,0],"4":[0,1,2,3,3],"3":[0,1,2,3,"a"],"5":[0,1,2,3,5]}';
      final data = jsonDecode(input);
      order.fromJson(data, "0");

      final p1 = TableVicinity(column: 0, row: 1);
      final p2 = TableVicinity(column: 1, row: 1);
      final r1 = TableVicinity(column: 4, row: 1);
      final r2 = TableVicinity(column: 3, row: 1);
      expect(model.map(p1), r1);
      expect(model.map(p2), r2);

      model.setVisibility(1, false);
      model.setVisibility(2, false);
      model.setVisibility(3, false);
      // setting cols to invisible should affect the output:
      final r3 = TableVicinity(column: 0, row: 1);
      expect(model.map(p1), r1);
      expect(model.map(p2), r3);
      final v1 = model[p1];
      final v2 = model[p2];

      expect(v1!.column, 4);
      expect(v2!.column, 0);
    });

    test("set column filter first", () {
      final order = SortColumnModel(simpleModel);
      final model = FilterColumnModel(order);
      model.setVisibility(1, false);
      model.setVisibility(2, false);
      model.setVisibility(3, false);

      final p1 = TableVicinity(column: 0, row: 1);
      final p2 = TableVicinity(column: 1, row: 1);
      final r1 = TableVicinity(column: 0, row: 1);
      final r2 = TableVicinity(column: 4, row: 1);
      expect(model.map(p1), r1);
      expect(model.map(p2), r2);

      order.moveColumn(0, 1);
      order.moveColumn(4, -1);
      // visibilities have to move as well - we have set 0 and to visible,
      // swapping them with invisible columns should not affect the order.

      expect(model.map(p1), r1);
      expect(model.map(p2), r2);
      final v1 = model[p1];
      final v2 = model[p2];

      expect(v1!.column, 0);
      expect(v2!.column, 4);
    });
  });

  group("merge models", () {
    test("toJson", () {
      ColumnMergeModel model = ColumnMergeModel(simpleModel);
      expect(model.toJson(), '{"active":false,"source":"","target":""}');
      model.setMergeOptions(
          active: true,
          source: "(row: 0, column: 1)",
          target: "(row: 0, column: 3)");
      expect(model.toJson(),
          '{"active":true,"source":"(row: 0, column: 1)","target":"(row: 0, column: 3)"}');
      expect(model.mergeSource, 1);
      expect(model.mergeTarget, 3);
      model.resetMerging();
      expect(model.toJson(), '{"active":false,"source":"","target":""}');
    });
    test("fromJson", () {
      ColumnMergeModel model = ColumnMergeModel(simpleModel);
      const inputFragment = '{"active":true,"source":"1","target":"3"}';
      const input = '{"0":$inputFragment}';
      final data = jsonDecode(input);
      model.fromJson(data, "0");
      expect(model.toJson(), inputFragment);
    });

    test("inactive", () {
      ColumnMergeModel model = ColumnMergeModel(simpleModel);
      for (int i = 0; i < simpleModel.columns; ++i) {
        final input = TableVicinity(row: 1, column: i);
        final output = model.map(input);
        expect(input, output);
        expect(model.columnWidth(i), 50 * (i + 1));
        expect(model[input]!.column, i);
        expect(model[input]!.content.length, 1);
      }
    });

    test("merge active", () {
      ColumnMergeModel model = ColumnMergeModel(simpleModel);
      model.setMergeOptions(
          active: true,
          source: "(row: 0, column: 1)",
          target: "(row: 0, column: 3)");
      expect(model.columns, simpleModel.columns - 1);
      expect(model.rows, simpleModel.rows);
      for (int i = 0; i < model.columns; ++i) {
        final input = TableVicinity(row: 1, column: i);
        final output = model.map(input);
        final expected = TableVicinity(row: 1, column: i + 1);
        if (i > 2) {
          expect(output, expected);
        } else {
          expect(input, output);
        }
        if (i == 1) {
          expect(model.columnWidth(i), 50 * (4));
        } else if (i < 3) {
          expect(model.columnWidth(i), 50 * (i + 1));
        } else {
          expect(model.columnWidth(i), 50 * (i + 2));
        }

        if (i == 1) {
          expect(model[input]!.content.length, 2);
        } else {
          expect(model[input]!.content.length, 1);
        }
      }
    });

    test("filter and merge columns", () {
      final filter = FilterColumnModel(simpleModel);
      final model = ColumnMergeModel(filter);
      filter.setVisibility(1, false);

      model.setMergeOptions(
          active: true,
          source: "(row: 0, column: 3)",
          target: "(row: 0, column: 4)");
      expect(model.mergeSource, 2);
      expect(model.mergeTarget, 3);

      filter.onColumnMoved(3, -1);
      expect(model.mergeSource, 1);
      expect(model.mergeTarget, 3);
    });
  });
}
