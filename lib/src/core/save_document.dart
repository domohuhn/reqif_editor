// Copyright 2026, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:reqif_editor/src/localization/app_localizations.dart';
import 'package:reqif_editor/src/document/document_controller.dart';

mixin SaveDocument<T extends StatefulWidget> on State<T> {
  Future<void> save(DocumentController documentController, int idx,
      {String? outputPath}) async {
    await documentController
        .save(idx, outputPath: outputPath)
        .onError(_showSaveError);
  }

  Future<void> saveCurrent(DocumentController documentController,
      {String? outputPath}) async {
    await documentController
        .saveCurrent(outputPath: outputPath)
        .onError(_showSaveError);
  }

  Future<void> saveAllModified(DocumentController documentController) async {
    await documentController.saveAllModified().onError(_showSaveError);
  }

  void _showSaveError(dynamic error, dynamic stacktrace) async {
    if (!mounted) {
      return;
    }
    Widget cancelButton = TextButton(
      child: Text(AppLocalizations.of(context)!.cancel),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.failedToSave),
      content: Text(
          "${AppLocalizations.of(context)!.failedToSaveBody}\n\n$error\n\n$stacktrace"),
      actions: [cancelButton],
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
    );
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
