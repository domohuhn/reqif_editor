// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:reqif_editor/src/document/document_remapping.dart';
import 'package:reqif_editor/src/document/document_service.dart';
import 'package:reqif_editor/src/document/reqif_search_controller.dart';
import 'package:reqif_editor/src/reqif/flat_document.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class DocumentData {
  String path;
  ReqIfDocument document;
  ReqIfFlatDocument flatDocument;
  DocumentService service;
  bool modified = false;
  int index;
  DocumentData(
      this.path, this.document, this.flatDocument, this.index, this.service) {
    _initializeHeadings();
    _initializeTexts();
    _initializeIds();
    _initializeLists();
    _initializeSelectionAndSearchData();
    _initializeFilterControllers();
  }
  static const String defaultHeadingName1 = "ReqIF.ChapterName";
  static const String defaultHeadingName2 = "ReqIF.Chapter";
  static const int fallbackHeadingColumn = 1;

  /// columns with the headings for each part.
  /// $1 ist the name, $2 the column index
  List<(String, int)> headings = [];

  /// columns with the id for each object.
  /// $1 ist the name, $2 the column index
  List<(String, int)> ids = [];

  /// columns with the text for each object.
  /// $1 ist the name, $2 the column index
  List<(String, int)> texts = [];

  void _initializeHeadings() {
    headings.clear();
    for (final part in flatDocument.parts) {
      final names = part.columnNames;
      int selected = -1;
      int counter = 0;
      for (final name in names) {
        if (name.contains(defaultHeadingName1) ||
            name.contains(defaultHeadingName2)) {
          selected = counter;
          break;
        }
        ++counter;
      }
      if (selected < 0) {
        // fallback, select first text or string column
        selected = 0;
        int counter = 0;
        for (final type in part.attributeDefinitions) {
          if (type.isText) {
            counter += 1;
            if (counter == fallbackHeadingColumn) {
              break;
            }
          }
          ++selected;
        }
      }
      headings.add((names[selected], selected));
    }
    assert(headings.length == flatDocument.partCount);
  }

  static const String defaultTextName = "ReqIF.Text";
  static const int fallbackTextColumn = 2;
  void _initializeTexts() {
    texts.clear();
    for (final part in flatDocument.parts) {
      final names = part.columnNames;
      int selected = -1;
      int counter = 0;
      for (final name in names) {
        if (name.contains(defaultTextName)) {
          selected = counter;
          break;
        }
        ++counter;
      }
      if (selected < 0) {
        // fallback, select second text or string column
        selected = 0;
        int counter = 0;
        for (final type in part.attributeDefinitions) {
          if (type.isText) {
            counter += 1;
            if (counter == fallbackTextColumn) {
              break;
            }
          }
          ++selected;
        }
      }
      texts.add((names[selected], selected));
    }
    assert(texts.length == flatDocument.partCount);
  }

  static const String defaultIdName1 = "Object Identifier";
  static const String defaultIdName2 = "Object ID";
  static const String defaultIdName3 = "Object Id";
  static const int fallbackIdColumn = 3;
  void _initializeIds() {
    ids.clear();
    for (final part in flatDocument.parts) {
      final names = part.columnNames;
      int selected = -1;
      int counter = 0;
      for (final name in names) {
        if (name.contains(defaultIdName1) ||
            name.contains(defaultIdName2) ||
            name.contains(defaultIdName3)) {
          selected = counter;
          break;
        }
        ++counter;
      }
      if (selected < 0) {
        // fallback, select second text or string column
        selected = 0;
        int counter = 0;
        for (final type in part.attributeDefinitions) {
          if (type.isText) {
            counter += 1;
            if (counter == fallbackTextColumn) {
              break;
            }
          }
          ++selected;
        }
      }
      ids.add((names[selected], selected));
    }
    assert(ids.length == flatDocument.partCount);
  }

  String get title => flatDocument.title;
  String? get comment => document.header.comment;
  set comment(String? comment) {
    if (comment != document.header.comment) {
      modified = true;
      document.header.comment = comment;
    }
  }

  void _initializeLists() {
    for (int i = 0; i < flatDocument.partCount; ++i) {
      partColumnWidths.add([]);
      partRowHeights.add([]);
    }
  }

  void _initializeSelectionAndSearchData() {
    for (int i = 0; i < flatDocument.partCount; ++i) {
      partSelections.add(const TableVicinity(column: -1, row: -1));
      columnMapping.add(ColumnMappings(flatDocument[i].columnCount));
      searchData.add(ReqIfSearchController(
          part: flatDocument[i], partNumber: i, map: columnMapping.last));
    }
  }

  /// Initializes the column ordering from a json string given in [strData]
  void columnOrderFromJson(String strData) {
    try {
      final data = jsonDecode(strData);
      for (int i = 0; i < columnMapping.length; ++i) {
        columnMapping[i].fromJson(data, i);
      }
    } catch (e) {
      // do nothing on failure - we use the default order
    }
  }

  /// Serializes the column ordering to a json string
  String columnOrderToJson() {
    StringBuffer rv = StringBuffer('{');
    for (int i = 0; i < columnMapping.length; ++i) {
      bool isLast = (i + 1) == columnMapping.length;
      rv.write(columnMapping[i].toJsonFragment(i));
      if (!isLast) {
        rv.write(',');
      }
    }
    rv.write('}');
    return rv.toString();
  }

  /// Reset the column ordering
  void resetColumnOrder() {
    for (int i = 0; i < columnMapping.length; ++i) {
      columnMapping[i].reset();
    }
  }

  void _initializeFilterControllers() {
    for (int i = 0; i < flatDocument.partCount; ++i) {
      List<TextEditingController> next = [];
      for (int p = 0; p < flatDocument[i].columnCount; ++p) {
        next.add(TextEditingController());
      }
      partFilterControllers.add(next);
    }
  }

  /// column widths per part
  final List<List<double>> partColumnWidths = <List<double>>[];

  /// row heights per part
  final List<List<double>> partRowHeights = <List<double>>[];

  /// Text editing controllers per part.
  ///
  /// Must be disposed before file is removed.
  final List<List<TextEditingController>> partFilterControllers =
      <List<TextEditingController>>[];

  /// [idx] is the position in the data model.
  double getRowOffset(int partNo, int idx) {
    double rv = 0.0;
    if (partNo < partRowHeights.length) {
      final rowHeights = partRowHeights[partNo];
      // row 0 is fixed at top -> add one to start and target
      final limit = min(idx + 1, rowHeights.length);
      for (int i = 1; i < limit; ++i) {
        rv += rowHeights[i];
      }
    }
    return rv;
  }

  final Map<String, ImageProvider> objectCache = {};

  String get baseFilePath => dirname(path);
  String joinPath(String object) => join(baseFilePath, object);
  String fixPath(String object) =>
      isAbsolute(object) ? object : joinPath(object);

  ImageProvider<Object>? getCachedImageOrLoad(String? path) {
    if (path == null) {
      return null;
    }
    if (objectCache.containsKey(path)) {
      return objectCache[path];
    }
    final absolutePath = fixPath(path);
    if (service.fileExistsSync(absolutePath)) {
      final image = FileImage(File(absolutePath));
      objectCache[path] = image;
      return image;
    } else {
      return null;
    }
  }

  void dispose() {
    for (final inner in partFilterControllers) {
      for (final control in inner) {
        control.dispose();
      }
    }
  }

  void applyFilter(bool active) {
    for (final part in flatDocument.parts.indexed) {
      part.$2.applyFilter(
          active, partFilterControllers[part.$1].map((e) => e.text).toList());
    }
    partColumnWidths.clear();
    partRowHeights.clear();
    _initializeLists();

    for (int i = 0; i < flatDocument.parts.length; ++i) {
      partSelections[i] = const TableVicinity(column: -1, row: -1);
      searchData[i].update();
    }
  }

  final List<TableVicinity> partSelections = [];
  final List<ReqIfSearchController> searchData = [];
  final List<ColumnMappings> columnMapping = [];

  void countMatches(int partNumber, String text) {
    if (partNumber < flatDocument.partCount) {
      searchData[partNumber].countMatches(text);
    }
  }

  int updateSelectionAndFindMatchRow(
      int partNumber, int matchNumber, String text) {
    if (partNumber < flatDocument.partCount) {
      return searchData[partNumber]
          .updateSelectionAndFindMatchRow(matchNumber, text);
    }
    return -1;
  }

  void moveColumn({required int part, required int column, required int move}) {
    if (part >= columnMapping.length ||
        part < 0 ||
        part >= partColumnWidths.length) {
      return;
    }
    columnMapping[part].moveColumn(column, move);
    moveDataInList<double>(partColumnWidths[part], column + 1, move);
    searchData[part].update();
  }
}
