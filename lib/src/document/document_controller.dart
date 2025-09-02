// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:io';

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:reqif_editor/src/document/document_data.dart';
import 'package:reqif_editor/src/document/document_service.dart';
import 'package:reqif_editor/src/reqif/flat_document.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_io.dart';
import 'package:reqif_editor/src/settings/settings_controller.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

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
    final columnOrder = _settings.fileColumnOrder(path);
    final columnVisibility = _settings.fileColumnVisibility(path);
    final columnMergeOptions = _settings.fileColumnMerge(path);
    final output = DocumentData(path, doc, flat, documents.length, _service,
        columnOrder: columnOrder,
        columnVisibility: columnVisibility,
        mergeData: columnMergeOptions);
    documents.add(output);
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
    triggerRebuild();
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
      contents = contents.replaceAll(RegExp('\r\n|\n'), '\r\n');
    }
    if (_settings.lineEndings == LineEndings.platform) {
      contents =
          contents.replaceAll(RegExp('\r\n|\n'), Platform.lineTerminator);
    }
    if (_settings.lineEndings == LineEndings.linefeed) {
      contents = contents.replaceAll('\r\n', '\n');
    }
    if (outputPath != null) {
      toSave.path = outputPath;
      await _settings.addOpenedFile(toSave.path, toSave.title);
    }
    await _service.write(toSave.path, contents);
    await _settings.updateFileColumnOrder(
        toSave.path, toSave.columnOrderToJson());
    await _settings.updateFileColumnVisibility(
        toSave.path, toSave.columnVisibilityToJson());
    await _settings.updateFileColumnMerge(
        toSave.path, toSave.columnMergeToJson());
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

  void setHeaderColumn(int docId, int partId, String heading) {
    assert(docId < documents.length);
    assert(partId < documents[docId].flatDocument.partCount);
    documents[docId].partColumnMerge[partId].mergeSourceColumnName = heading;
    notifyListeners();
  }

  void _makeMergeColumnsVisible(int docId, int partId) {
    if (docId >= documents.length ||
        partId >= documents[docId].flatDocument.partCount) {
      return;
    }
    final model = documents[docId].partColumnMerge[partId];
    final order = documents[docId].partColumnOrder[partId];
    final visibility = documents[docId].partColumnFilter[partId];
    final names = documents[docId].flatDocument[partId].columnNames;
    final String source = model.mergeSourceColumnName;
    final String target = model.mergeTargetColumnName;
    final int sourceIdx =
        order.inverseMapColumn(names.indexWhere((v) => v == source) + 1);
    final int targetIdx =
        order.inverseMapColumn(names.indexWhere((v) => v == target) + 1);
    visibility.setVisibility(sourceIdx, true);
    visibility.setVisibility(targetIdx, true);
  }

  void setMergeActive(int docId, int partId, bool value) {
    if (docId >= documents.length ||
        partId >= documents[docId].flatDocument.partCount) {
      return;
    }
    if (value) {
      _makeMergeColumnsVisible(docId, partId);
    }
    documents[docId].partColumnMerge[partId].mergeActive = value;
    notifyListeners();
  }

  bool mergeActive(int docId, int partId) {
    if (docId >= documents.length ||
        partId >= documents[docId].flatDocument.partCount) {
      return false;
    }
    return documents[docId].partColumnMerge[partId].mergeActive;
  }

  void setMergeColumns(int docId, int partId, String? source, String? target) {
    if (docId >= documents.length ||
        partId >= documents[docId].flatDocument.partCount) {
      return;
    }
    documents[docId]
        .partColumnMerge[partId]
        .setMergeOptions(source: source, target: target);
    if (mergeActive(docId, partId)) {
      _makeMergeColumnsVisible(docId, partId);
    }
    documents[docId]
        .partColumnMerge[partId]
        .setMergeOptions(source: source, target: target);
    notifyListeners();
  }

  // gets the index of the column to merge without any reordering.
  // returns an empty string if not set
  String columnMergeTarget(int docId, int partId) {
    if (docId >= documents.length ||
        partId >= documents[docId].flatDocument.partCount) {
      return "";
    }
    final model = documents[docId].partColumnMerge[partId];
    return model.mergeTargetColumnName;
  }

  // gets the index of the column to merge without any reordering.
  // returns an empty string if not set
  String columnMergeSource(int docId, int partId) {
    if (docId >= documents.length ||
        partId >= documents[docId].flatDocument.partCount) {
      return "";
    }
    final model = documents[docId].partColumnMerge[partId];
    return model.mergeSourceColumnName;
  }

  ReqIfDocumentPart get visiblePart =>
      documents[visibleDocumentNumber].flatDocument[visibleDocumentPartNumber];
  DocumentData get visibleData => documents[visibleDocumentNumber];
  int get headingsColumn {
    if (visibleDocumentNumber < 0 ||
        visibleDocumentNumber >= documents.length ||
        visibleDocumentPartNumber < 0 ||
        visibleDocumentPartNumber >
            documents[visibleDocumentNumber].flatDocument.partCount) {
      return -1;
    }
    return visibleData.headingsColumn(visibleDocumentPartNumber);
  }

  DocumentData operator [](int idx) {
    return documents[idx];
  }

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
    documentWasModified(document);
  }

  void setColumnVisibility(
      {required int document,
      required int part,
      required int column,
      required bool visible}) {
    if (document < 0 || document >= length) {
      return;
    }
    documents[document]
        .setColumnVisibility(part: part, column: column, visible: visible);
    documentWasModified(document);
  }

  void resetColumnOrder({required int document, required int part}) {
    _resetAndFixMergeColumns(
        document: document,
        part: part,
        cb: () => documents[document].resetColumnOrder(part));
  }

  void resetVisibility({required int document, required int part}) {
    _resetAndFixMergeColumns(
        document: document,
        part: part,
        cb: () => documents[document].resetColumnVisibility(part));
  }

  void _resetAndFixMergeColumns(
      {required int document, required int part, required bool Function() cb}) {
    if (document < 0 ||
        document >= length ||
        part < 0 ||
        part >= documents[document].flatDocument.partCount) {
      return;
    }
    final mergeModel = documents[document].partColumnMerge[part];
    final visibilityModel = documents[document].partColumnFilter[part];
    final int mergeSource = visibilityModel
        .map(TableVicinity(row: 0, column: mergeModel.mergeSource))
        .column;
    final int mergeTarget = visibilityModel
        .map(TableVicinity(row: 0, column: mergeModel.mergeTarget))
        .column;
    if (cb()) {
      mergeModel.setMergeColumnNumbers(
          source: mergeSource, target: mergeTarget);
      documentWasModified(document);
    }
  }
}

Future<ReqIfDocument?> _parseAsync(String contents) async {
  // show loading screen for at least two seconds
  final start = DateTime.now();
  final doc = parseXMLString(contents);
  ReqIfDocument parsed = ReqIfDocument.parse(doc);
  final end = DateTime.now();
  final diff = end.difference(start);
  if (diff.inSeconds < 2) {
    await Future.delayed(const Duration(seconds: 2));
  }
  return parsed;
}
