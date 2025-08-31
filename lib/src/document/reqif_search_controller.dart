// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:reqif_editor/src/document/model/table_model.dart';
import 'package:reqif_editor/src/reqif/flat_document.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class ReqIfSearchController {
  TableVicinity matchPosition = const TableVicinity(column: -1, row: -1);
  final TextEditingController searchController = TextEditingController();
  int matches = 0;
  int currentMatch = -1;
  bool caseSensitive = false;
  final int partNumber;
  ReqIfDocumentPart part;
  TableModel map;

  ReqIfSearchController(
      {required this.part, required this.partNumber, required this.map});

  void update() {
    String filter = searchController.text;
    countMatches(filter);
    currentMatch = min(currentMatch, matches - 1);
    updateSelectionAndFindMatchRow(currentMatch, filter);
  }

  void countMatches(String text) {
    if (text == "") {
      matches = 0;
      currentMatch = -1;
      matchPosition = const TableVicinity(column: -1, row: -1);
      return;
    }
    matches = part.countMatches(text, caseSensitive);
    if (matches == 0) {
      currentMatch = -1;
      matchPosition = const TableVicinity(column: -1, row: -1);
    }
  }

  int updateSelectionAndFindMatchRow(int matchNumber, String text) {
    if (text == "") {
      matches = 0;
      currentMatch = -1;
      matchPosition = const TableVicinity(column: -1, row: -1);
      return -1;
    }
    final position =
        part.matchAt(text, caseSensitive, min(matchNumber, matches - 1));
    if (position.$1 < 0) {
      matches = 0;
      currentMatch = -1;
      matchPosition = const TableVicinity(column: -1, row: -1);
      return -1;
    }
    matchPosition = map.inverseMap(
        TableVicinity(row: position.$1 + 1, column: position.$2 + 1));
    return position.$1;
  }
}
