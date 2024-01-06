// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/document/document_view.dart';

mixin OpenDocument<T extends StatefulWidget> on State<T> {
  void openPath(DocumentController documentController, String path) {
    documentController.loadDocument(path, _showLoadError).then((value) {
      if (value) {
        Navigator.popAndPushNamed(context, ReqIfDocumentView.routeName);
      }
    });
  }

  void _showLoadError(dynamic error, dynamic stacktrace) async {
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
      title: Text(AppLocalizations.of(context)!.failedToLoad),
      content: Text(
          "${AppLocalizations.of(context)!.failedToLoadBody}\n\n$error\n\n$stacktrace"),
      actions: [cancelButton],
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
    );
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
    return null;
  }
}
