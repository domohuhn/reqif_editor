// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:convert';
import 'dart:io';

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:reqif_editor/src/document/document_data.dart';
import 'package:reqif_editor/src/document/document_service.dart';
import 'package:reqif_editor/src/reqif/flat_document.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';
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

  String? _queuedLoadPath;

  void enqueueFileLoad(String? path) {
    _queuedLoadPath = path;
  }

  String? get queuedLoadPath => _queuedLoadPath;

  Future<bool> loadDocument(String path,
      [void Function(dynamic, dynamic)? onError, String? doesNotExist]) async {
    final exists = await _service.fileExists(path);
    if (!exists) {
      if (onError != null) {
        onError(doesNotExist, path);
      }
      return false;
    }
    try {
      String contents;
      Map<String, ImageProvider<Object>> imageCache = {};
      if (_isCompressedReqif(path)) {
        contents = await _loadReqifz(path, imageCache, onError);
      } else {
        contents = await _service
            .read(path)
            .timeout(const Duration(seconds: 30))
            .onError((error, stackTrace) {
          if (onError != null) {
            onError(error, stackTrace);
          }
          return "";
        });
      }
      if (contents == "") {
        if (onError != null) {
          onError("File is empty", path);
        }
        return false;
      }
      final output = await _parseReqifFromString(path, contents);
      output.extendImageCache(imageCache);
      documents.add(output);
      _addOpenedFile(output);
      notifyListeners();
      return true;
    } catch (e) {
      if (onError != null) {
        onError(e, path);
      }
      return false;
    }
  }

  Future<DocumentData> _parseReqifFromString(String path, String contents,
      [void Function(dynamic, dynamic)? onError]) async {
    final doc =
        await compute(_parseAsync, contents).onError((error, stackTrace) {
      if (onError != null) {
        onError(error, stackTrace);
      }
      return null;
    });
    if (doc == null) {
      return Future.error("Failed to parse");
    }
    final flat = ReqIfFlatDocument.buildFlatDocument(doc);
    final columnOrder = _settings.fileColumnOrder(path);
    final columnVisibility = _settings.fileColumnVisibility(path);
    final columnMergeOptions = _settings.fileColumnMerge(path);
    final output = DocumentData(path, doc, flat, documents.length, _service,
        columnOrder: columnOrder,
        columnVisibility: columnVisibility,
        mergeData: columnMergeOptions);
    return output;
  }

  bool _isCompressedReqif(String path) {
    return path.endsWith(".reqifz");
  }

  bool _isUTF8(Uint8List data) {
    final len = min(data.length, 100);
    final encodingSequence = [0x65, 0x6E, 0x63, 0x6F, 0x64, 0x69, 0x6E, 0x67];
    final utf8Sequence = [0x55, 0x54, 0x46, 0x2D, 0x38];
    final openBrace = 0x3C;
    final closeBrace = 0x3E;
    final questionMark = 0x3F;
    final equals = 0x3D;

    int lastCodePoint = 0;
    bool inProcessingInstruction = false;
    bool encodingFound = false;
    bool equalsFound = false;

    int indexInSequence = 0;

    for (int i = 0; i < len; ++i) {
      final current = data[i];
      if (lastCodePoint == openBrace && current == questionMark) {
        inProcessingInstruction = true;
      }
      if (inProcessingInstruction) {
        if (lastCodePoint == questionMark && current == closeBrace) {
          inProcessingInstruction = false;
          encodingFound = false;
        } else if (!encodingFound) {
          if (current == encodingSequence[indexInSequence]) {
            indexInSequence++;
          } else {
            indexInSequence = 0;
          }
          encodingFound = indexInSequence == encodingSequence.length;
          if (encodingFound) {
            indexInSequence = 0;
          }
        } else {
          if (current == equals) {
            if (equalsFound) {
              equalsFound = false;
              encodingFound = false;
            } else {
              equalsFound = true;
            }
          }
          if (equalsFound) {
            if (current == utf8Sequence[indexInSequence]) {
              indexInSequence++;
            } else {
              indexInSequence = 0;
            }
            if (indexInSequence == utf8Sequence.length) {
              return true;
            }
          }
        }
      } else {
        indexInSequence = 0;
        encodingFound = false;
      }
      lastCodePoint = data[i];
    }
    return false;
  }

  Future<String> _loadReqifz(
      String path, Map<String, ImageProvider<Object>> images,
      [void Function(dynamic, dynamic)? onError]) async {
    final zipContents = await _service
        .loadZipArchive(path)
        .timeout(const Duration(seconds: 30))
        .onError((error, stackTrace) {
      if (onError != null) {
        onError(error, stackTrace);
      }
      return {};
    });

    String rawReqif = "";
    int countReqif = 0;
    for (final entry in zipContents.entries) {
      if (entry.key.endsWith(".png")) {
        final fileBytes = entry.value;
        if (fileBytes.isNotEmpty) {
          images[entry.key] = MemoryImage(fileBytes);
        }
      }
      if (entry.key.endsWith(".reqif")) {
        final fileBytes = entry.value;
        if (fileBytes.isNotEmpty) {
          if (_isUTF8(fileBytes)) {
            rawReqif = Utf8Decoder(allowMalformed: true).convert(fileBytes);
          } else {
            try {
              rawReqif = Utf8Decoder().convert(fileBytes);
            } catch (e) {
              rawReqif = Latin1Decoder(allowInvalid: true).convert(fileBytes);
            }
          }
          countReqif += 1;
        }
      }
    }
    // TODO: if we want to support more than one reqif document per file, we must rework the persistence data.
    if (countReqif != 1) {
      return Future.error("Only one reqif per reqifz file is supported!");
    }
    return rawReqif;
  }

  Future<void> _saveReqifz(String archivePath, String contents,
      Map<String, ImageProvider> embeddedObjects,
      [Encoding? encoding]) async {
    assert(archivePath.endsWith(".reqifz"));
    final archiveBaseName = basename(archivePath);
    final reqifFileName =
        archiveBaseName.substring(0, archiveBaseName.length - 1);
    Map<String, Uint8List> files = {};
    encoding ??= utf8;
    final encoded = encoding.encode(contents);
    files[reqifFileName] = Uint8List.fromList(encoded);

    for (final img in embeddedObjects.entries) {
      final data = img.value;
      if (data is MemoryImage) {
        files[img.key] = data.bytes;
      }
    }

    await _service.saveAsZipArchive(archivePath, files);
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

  bool get hasOpenDocuments => length > 0;

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

    var mode = _settings.exportCompatibility;
    if (mode == ExportCompatibility.automatic) {
      final originalId = toSave.document.toolId;
      if (originalId.contains("Code")) {
        mode = ExportCompatibility.code;
      } else if (originalId.contains("PTC")) {
        mode = ExportCompatibility.ptc;
      } else {
        mode = ExportCompatibility.none;
      }
    }
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
    var contents = toSave.document.xmlString(mode);
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
      if (outputPath.endsWith(".reqifz") && !toSave.path.endsWith(".reqifz")) {
        throw ReqIfError(
            "Converting a '.reqif' file to '.reqifz' is currently not supported");
      }
      toSave.path = outputPath;
      _addOpenedFile(toSave);
    }
    if (_isCompressedReqif(toSave.path)) {
      await _saveReqifz(
          toSave.path, contents, toSave.objectCache, toSave.document.encoding);
    } else {
      await _service.write(toSave.path, contents, toSave.document.encoding);
    }
    await _settings.updateFileColumnOrder(
        toSave.path, toSave.columnOrderToJson());
    await _settings.updateFileColumnVisibility(
        toSave.path, toSave.columnVisibilityToJson());
    await _settings.updateFileColumnMerge(
        toSave.path, toSave.columnMergeToJson());
    toSave.modified = false;
  }

  void _addOpenedFile(DocumentData data) async {
    try {
      String title = data.title;
      for (final part in data.flatDocument.parts) {
        final name = part.name;
        if (name != null) {
          title += " | $name";
        }
      }
      await _settings.addOpenedFile(data.path, title);
    } catch (e) {
      return;
    }
  }

  Future<void> saveAllModified() async {
    for (int i = 0; i < documents.length; ++i) {
      if (documents[i].modified) {
        await save(i);
      }
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
