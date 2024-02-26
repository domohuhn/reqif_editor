// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:io';

import 'package:path/path.dart';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:reqif_editor/src/document/document_service.dart';
import 'package:reqif_editor/src/reqif/flat_document.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_io.dart';
import 'package:reqif_editor/src/settings/settings_controller.dart';
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
}

class ReqIfSearchController {
  TableVicinity matchPosition = const TableVicinity(column: -1, row: -1);
  final TextEditingController searchController = TextEditingController();
  int matches = 0;
  int currentMatch = -1;
  bool caseSensitive = false;
  final int partNumber;
  ReqIfDocumentPart part;
  ColumnMappings map;

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
    matchPosition = TableVicinity(
        row: position.$1 + 1, column: map.inverse(position.$2) + 1);
    return position.$1;
  }
}

/// A class that many Widgets can interact with to read the document state,
/// update the document, trigger a load or save.
///
/// Controllers glue Data Services to Flutter Widgets. The SettingsController
/// uses the SettingsService to store and retrieve user settings.
class DocumentController with ChangeNotifier {
  DocumentController(this._service, this._settings);
  List<DocumentData> documents = [];
  final SettingsController _settings;
  final DocumentService _service;

  Future<bool> loadDocument(String path,
      [void Function(dynamic, dynamic)? onError]) async {
    final contents = await _service.read(path);
    final doc =
        await compute(_parseAsync, contents).onError((error, stackTrace) {
      if (onError != null) {
        onError(error, stackTrace);
      }
      return null;
    });
    if (doc == null) {
      return false;
    }
    final flat = ReqIfFlatDocument.buildFlatDocument(doc);
    documents.add(DocumentData(path, doc, flat, documents.length, _service));
    _settings.addOpenedFile(path, flat.title);
    notifyListeners();
    return true;
  }

  void forceRedraw() {
    notifyListeners();
  }

  void closeDocument(int idx) {
    if (idx >= documents.length) {
      return;
    }
    documents[idx].dispose();
    documents.removeAt(idx);
    if (visibleDocumentNumber >= idx && visibleDocumentNumber > 0) {
      visibleDocumentNumber -= 1;
    }
    _sanitizeValues();
    notifyListeners();
  }

  void _sanitizeValues() {
    if (visibleDocumentNumber >= documents.length) {
      visibleDocumentNumber = max(0, documents.length - 1);
    }
    if (visibleDocumentNumber >= documents.length ||
        visibleDocumentPartNumber >= visibleData.flatDocument.partCount) {
      visibleDocumentPartNumber = 0;
    }
  }

  void documentWasModified(int idx) {
    if (documents.length <= idx) {
      return;
    }
    documents[idx].modified = true;
    notifyListeners();
  }

  void triggerRebuild() {
    notifyListeners();
  }

  int get length => documents.length;
  bool get modified => documents.any((element) => element.modified);

  void setComment(int idx, String comment) {
    if (documents.length <= idx) {
      return;
    }
    documents[idx].comment = comment.isNotEmpty ? comment : null;
  }

  Future<void> save(int idx, {String? outputPath}) async {
    if (documents.length <= idx) {
      return;
    }
    final toSave = documents[idx];
    if (_settings.updateCreationTime) {
      toSave.document.updateDocumentCreationTime();
    }
    if (_settings.updateDocumentUUID) {
      toSave.document.updateDocumentId();
    }
    if (_settings.updateTool) {
      toSave.document.toolId = "ReqIF Editor Version 1.0";
      toSave.document.sourceToolId = "com.github.reqif_editor.reqif_editor";
    }
    var contents = toSave.document.xmlString;
    if (_settings.lineEndings == LineEndings.carriageReturnLinefeed) {
      contents = contents.replaceAll('\n', '\r\n');
    }
    if (outputPath != null) {
      await _service.write(outputPath, contents);
      toSave.path = outputPath;
    } else {
      await _service.write(toSave.path, contents);
    }
    toSave.modified = false;
  }

  Future<void> saveAllModified() async {
    for (int i = 0; i < documents.length; ++i) {
      await save(i);
    }
  }

  Future<void> saveCurrent({String? outputPath}) async {
    await save(visibleDocumentNumber, outputPath: outputPath);
    notifyListeners();
  }

  int _visibleDocumentNumber = 0;
  set visibleDocumentNumber(int i) {
    if (i == _visibleDocumentNumber || documents.length <= i) {
      return;
    }
    _visibleDocumentNumber = i;
    notifyListeners();
  }

  int _visibleDocumentPartNumber = 0;
  set visibleDocumentPartNumber(int i) {
    if (i == _visibleDocumentPartNumber ||
        documents.isEmpty ||
        visibleDocumentNumber >= documents.length ||
        visibleData.flatDocument.partCount <= i) {
      return;
    }
    _visibleDocumentPartNumber = i;
    notifyListeners();
  }

  int get visibleDocumentNumber => _visibleDocumentNumber;
  int get visibleDocumentPartNumber => _visibleDocumentPartNumber;
  bool get hasVisibleDocument => _visibleDocumentNumber < documents.length;
  bool get hasVisibleDocumentPart =>
      hasVisibleDocument &&
      _visibleDocumentPartNumber <
          documents[visibleDocumentNumber].flatDocument.partCount;

  void setHeaderColumn(int docId, int partId, (String, int) heading) {
    assert(docId < documents.length);
    assert(partId < documents[docId].flatDocument.partCount);
    documents[docId].headings[partId] = heading;
    notifyListeners();
  }

  ReqIfDocumentPart get visiblePart =>
      documents[visibleDocumentNumber].flatDocument[visibleDocumentPartNumber];
  DocumentData get visibleData => documents[visibleDocumentNumber];
  int get headingsColumn =>
      documents[visibleDocumentNumber].headings[visibleDocumentPartNumber].$2;

  DocumentData operator [](int idx) {
    return documents[idx];
  }

  List<double> get columnWidths => documents[visibleDocumentNumber]
      .partColumnWidths[visibleDocumentPartNumber];

  List<double> get rowHeights => documents[visibleDocumentNumber]
      .partRowHeights[visibleDocumentPartNumber];

  ScrollController get horizontalScrollController =>
      _horizontalScrollController;
  ScrollController get verticalScrollController => _verticalScrollController;

  void setPosition({int? document, int? part, int? row}) {
    setRestoreScrollPositions(false);
    bool changed = false;
    if (document != null) {
      changed = visibleDocumentNumber != document;
      visibleDocumentNumber = document;
    }
    if (part != null) {
      changed = changed || visibleDocumentPartNumber != part;
      visibleDocumentPartNumber = part;
    }
    _sanitizeValues();
    if (row != null &&
        visibleDocumentNumber < documents.length &&
        hasVisibleDocumentPart) {
      double offset = visibleData.getRowOffset(visibleDocumentPartNumber, row);
      _verticalScrollController.animateTo(offset,
          duration: const Duration(seconds: 1), curve: Curves.easeOutQuart);
    }
    if (changed) {
      visibleData.partSelections[visibleDocumentPartNumber] =
          const TableVicinity(column: -1, row: -1);
      notifyListeners();
    }
  }

  void refreshScrollControllers() {
    _verticalScrollController = ScrollController(onAttach: (position) {
      if (_restoreScrollVerticalPositions) {
        position.restoreOffset(_verticalOffset, initialRestore: true);
        _restoreScrollVerticalPositions = false;
      }
    });
    _horizontalScrollController = ScrollController(onAttach: (position) {
      if (_restoreScrollHorizontalPositions) {
        position.restoreOffset(_horizontalOffset, initialRestore: true);
        _restoreScrollHorizontalPositions = false;
      }
    });
  }

  ScrollController _verticalScrollController = ScrollController();
  ScrollController _horizontalScrollController = ScrollController();

  bool _restoreScrollHorizontalPositions = false;
  bool _restoreScrollVerticalPositions = false;
  double _verticalOffset = 0.0;
  double _horizontalOffset = 0.0;

  void setRestoreScrollPositions(bool v) {
    _restoreScrollHorizontalPositions = v;
    _restoreScrollVerticalPositions = v;
    if (v) {
      _verticalOffset = _verticalScrollController.offset;
      _horizontalOffset = _horizontalScrollController.offset;
    }
  }

  void applyFilter(bool active) {
    for (final doc in documents) {
      doc.applyFilter(active);
    }
    notifyListeners();
  }

  void moveColumn(
      {required int document,
      required int part,
      required int column,
      required int move}) {
    if (document < 0 || document >= length) {
      return;
    }
    documents[document].moveColumn(part: part, column: column, move: move);
    notifyListeners();
  }
}

Future<ReqIfDocument?> _parseAsync(String contents) async {
  final doc = parseXMLString(contents);
  ReqIfDocument parsed = ReqIfDocument.parse(doc);
  return parsed;
}
