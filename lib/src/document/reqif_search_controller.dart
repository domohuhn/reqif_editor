// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:reqif_editor/src/document/model/table_model.dart';
import 'package:reqif_editor/src/reqif/reqif_attribute_values.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class ReqIfSearchController {
  TableVicinity matchPosition = const TableVicinity(column: -1, row: -1);
  final TextEditingController searchController = TextEditingController();
  int matches = 0;
  int currentMatch = -1;
  bool caseSensitive = false;
  TableModel map;
  List<TableVicinity> allMatches = [];

  ReqIfSearchController(this.map);

  void update() {
    String filter = searchController.text;
    countMatches(filter);
    currentMatch = min(currentMatch, matches - 1);
    updateSelectionAndFindMatchRow(currentMatch, filter);
  }

  void _fillList(String text) {
    allMatches.clear();
    final regex = RegExp(text, caseSensitive: caseSensitive);
    for (int row = 1; row < map.rows; row++) {
      for (int col = 1; col < map.columns; col++) {
        final position = TableVicinity(row: row, column: col);
        final cell = map[position];
        if (cell != null && cell.content.isNotEmpty) {
          for (final attr in cell.content) {
            if (attr is ReqIfAttributeValue &&
                regex.hasMatch(attr.toStringWithNewlines())) {
              allMatches.add(position);
            }
          }
        }
      }
    }
  }

  void countMatches(String text) {
    if (text == "") {
      allMatches.clear();
      matches = 0;
      currentMatch = -1;
      matchPosition = const TableVicinity(column: -1, row: -1);
      return;
    }
    _fillList(text);
    matches = allMatches.length;
    if (allMatches.isEmpty) {
      currentMatch = -1;
      matchPosition = const TableVicinity(column: -1, row: -1);
    }
  }

  int updateSelectionAndFindMatchRow(int matchNumber, String text) {
    if (text == "" || matches == 0) {
      matches = 0;
      currentMatch = -1;
      matchPosition = const TableVicinity(column: -1, row: -1);
      return -1;
    }
    final matchIdx = max(0, min(matchNumber, matches - 1));
    final position = allMatches[matchIdx];
    if (position.row < 0) {
      matches = 0;
      currentMatch = -1;
      matchPosition = const TableVicinity(column: -1, row: -1);
      return -1;
    }
    matchPosition = position;
    return position.row;
  }
}
