// Copyright 2025, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:path/path.dart';

import 'package:flutter/material.dart';
import 'package:reqif_editor/src/document/document_service.dart';
import 'package:reqif_editor/src/document/model/column_merge_model.dart';
import 'package:reqif_editor/src/document/model/filter_column_model.dart';
import 'package:reqif_editor/src/document/model/reqif_model.dart';
import 'package:reqif_editor/src/document/model/sort_column_model.dart';
import 'package:reqif_editor/src/document/model/table_model.dart';
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
      this.path, this.document, this.flatDocument, this.index, this.service,
      {required String columnOrder,
      required String columnVisibility,
      required String mergeData}) {
    initializePartModels(
        columnOrder: columnOrder,
        columnVisibility: columnVisibility,
        mergeData: mergeData);
    _initializeTexts();
    _initializeIds();
    _initializeSelectionAndSearchData();
    _initializeFilterControllers();
  }
  static const String defaultHeadingName1 = "ReqIF.ChapterName";
  static const String defaultHeadingName2 = "ReqIF.Chapter";
  static const int fallbackHeadingColumn = 1;

  /// columns with the id for each object.
  /// $1 ist the name, $2 the column index
  List<(String, int)> ids = [];

  /// columns with the text for each object.
  /// $1 ist the name, $2 the column index
  List<(String, int)> texts = [];

  /// Initializes the headings and merge target if not already selected.
  void _initializeHeadings() {
    for (final part in flatDocument.parts.indexed) {
      if (partColumnMerge[part.$1].mergeSourceColumnName != "") {
        continue;
      }
      final names = part.$2.columnNames;
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
        for (final type in part.$2.attributeDefinitions) {
          if (type.isText) {
            counter += 1;
            if (counter == fallbackHeadingColumn) {
              break;
            }
          }
          ++selected;
        }
      }
      partColumnMerge[part.$1].setMergeOptions(source: names[selected]);
    }
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

  int headingsColumn(int part) {
    if (part < 0 || part >= flatDocument.partCount) {
      return -1;
    }
    final name = partColumnMerge[part].mergeSourceColumnName;
    return flatDocument[part].columnNames.indexWhere((v) => v == name);
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

  void _initializeSelectionAndSearchData() {
    for (int i = 0; i < partModels.length; ++i) {
      partSelections.add(const TableVicinity(column: -1, row: -1));
      searchData.add(ReqIfSearchController(partModels[i]));
    }
  }

  /// Initializes the column ordering from a json string given in [strData]
  void _columnOrderFromJson(String strData) {
    try {
      final data = jsonDecode(strData);
      for (int i = 0; i < partColumnOrder.length; ++i) {
        partColumnOrder[i].fromJson(data, "$i");
      }
    } catch (e) {
      resetAllColumnOrders();
    }
  }

  /// Initializes the column visibility from a json string given in [strData]
  void _columnVisibilityFromJson(String strData) {
    try {
      final data = jsonDecode(strData);
      for (int i = 0; i < partColumnFilter.length; ++i) {
        partColumnFilter[i].visibilityFromJson(data, "$i");
      }
    } catch (e) {
      for (int i = 0; i < partColumnFilter.length; ++i) {
        resetColumnVisibility(i);
      }
    }
  }

  /// Initializes the column merge options from a json string given in [strData]
  void _columnMergeFromJson(String strData) {
    try {
      final data = jsonDecode(strData);
      for (int i = 0; i < partColumnMerge.length; ++i) {
        partColumnMerge[i].fromJson(data, "$i");
      }
    } catch (e) {
      for (int i = 0; i < partColumnFilter.length; ++i) {
        partColumnMerge[i].resetMerging();
      }
    }
    _initializeHeadings();
  }

  /// Serializes the column merge options to a json string
  String columnMergeToJson() {
    StringBuffer rv = StringBuffer('{');
    for (int i = 0; i < partColumnMerge.length; ++i) {
      bool isLast = (i + 1) == partColumnMerge.length;
      rv.write('"$i":');
      rv.write(partColumnMerge[i].toJson());
      if (!isLast) {
        rv.write(',');
      }
    }
    rv.write('}');
    return rv.toString();
  }

  /// Serializes the column ordering to a json string
  String columnOrderToJson() {
    StringBuffer rv = StringBuffer('{');
    for (int i = 0; i < partColumnOrder.length; ++i) {
      bool isLast = (i + 1) == partColumnOrder.length;
      rv.write('"$i":');
      rv.write(partColumnOrder[i].toJson());
      if (!isLast) {
        rv.write(',');
      }
    }
    rv.write('}');
    return rv.toString();
  }

  /// Reset the column ordering
  void resetAllColumnOrders() {
    for (int i = 0; i < partColumnOrder.length; ++i) {
      resetColumnOrder(i);
    }
  }

  /// Resets the column ordering for the given [part].
  ///
  /// Returns true if values were changed.
  bool resetColumnOrder(int part) {
    if (part < partColumnOrder.length) {
      // get visible real cols
      var model = partColumnFilter[part];
      var visibilityCols = [];
      for (int i = 0; i < model.columns; ++i) {
        visibilityCols.add(model.map(TableVicinity(row: 0, column: i)).column);
      }
      final rv = partColumnOrder[part].resetOrder();
      if (rv) {
        model.resetVisibility(false);
        for (int i = 0; i < visibilityCols.length; ++i) {
          model.setVisibility(visibilityCols[i], true);
        }
      }
      return rv;
    }
    return false;
  }

  /// Serializes the column visibility to a json string
  String columnVisibilityToJson() {
    StringBuffer rv = StringBuffer('{');
    for (int i = 0; i < partColumnFilter.length; ++i) {
      bool isLast = (i + 1) == partColumnFilter.length;
      rv.write('"$i":');
      rv.write(partColumnFilter[i].toJson());
      if (!isLast) {
        rv.write(',');
      }
    }
    rv.write('}');
    return rv.toString();
  }

  /// Resets the column visibility for the given [part].
  ///
  /// Returns true if values were changed.
  bool resetColumnVisibility(int part) {
    if (part < partColumnFilter.length) {
      return partColumnFilter[part].resetVisibility();
    }
    return false;
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

  List<ColumnMergeModel> partColumnMerge = [];
  List<SortColumnModel> partColumnOrder = [];
  List<FilterColumnModel> partColumnFilter = [];
  List<TableModel> partModels = [];

  void initializePartModels(
      {required String columnOrder,
      required String columnVisibility,
      required String mergeData}) {
    partColumnMerge.clear();
    partColumnOrder.clear();
    partColumnFilter.clear();
    partModels.clear();
    for (int i = 0; i < flatDocument.partCount; ++i) {
      final dataModel = ReqIfModel(flatDocument[i]);
      final order = SortColumnModel(dataModel);
      final visibility = FilterColumnModel(order);
      final columnMerge = ColumnMergeModel(visibility);
      partColumnMerge.add(columnMerge);
      partColumnOrder.add(order);
      partColumnFilter.add(visibility);
      partModels.add(columnMerge);
    }
    _columnOrderFromJson(columnOrder);
    _columnVisibilityFromJson(columnVisibility);
    _columnMergeFromJson(mergeData);
  }

  /// Text editing controllers per part.
  ///
  /// Must be disposed before file is removed.
  final List<List<TextEditingController>> partFilterControllers =
      <List<TextEditingController>>[];

  /// [idx] is the position in the data model.
  double getRowOffset(int partNo, int rowIndex) {
    double rv = 0.0;
    if (partNo < partModels.length) {
      final model = partModels[partNo];
      // row 0 is fixed at top -> add one to start
      final limit = min(rowIndex, model.rows);
      for (int i = 1; i < limit; ++i) {
        rv += model.rowHeight(i);
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
      final filterList =
          partFilterControllers[part.$1].map((e) => e.text).toList();
      List<int> orColumns = [];
      if (part.$1 < partColumnMerge.length) {
        final merge = partColumnMerge[part.$1];
        if (merge.mergeActiveAndValid) {
          int source = part.$2.columnNames
              .indexWhere((v) => v == merge.mergeSourceColumnName);
          int target = part.$2.columnNames
              .indexWhere((v) => v == merge.mergeTargetColumnName);
          orColumns.add(source);
          orColumns.add(target);
          if (source < filterList.length && target < filterList.length) {
            filterList[target] = filterList[source];
          }
        }
      }
      part.$2.applyFilter(active, filterList, columnsToOr: orColumns);
    }

    for (int i = 0; i < flatDocument.parts.length; ++i) {
      partSelections[i] = const TableVicinity(column: -1, row: -1);
      final model = partModels[i].baseModel;
      if (model is ReqIfModel) {
        model.onSizeChange();
      }
      searchData[i].update();
    }
  }

  final List<TableVicinity> partSelections = [];
  final List<ReqIfSearchController> searchData = [];

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
    if (part >= partColumnOrder.length ||
        part < 0 ||
        part >= partColumnOrder.length) {
      return;
    }
    partColumnOrder[part].moveColumn(column, move);
    searchData[part].update();
  }

  void setColumnVisibility(
      {required int part, required int column, required bool visible}) {
    if (part >= partColumnFilter.length ||
        part < 0 ||
        part >= partColumnFilter.length) {
      return;
    }
    partColumnFilter[part].setVisibility(column, visible);
    searchData[part].update();
  }
}
