// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:reqif_editor/src/localization/app_localizations.dart';
import 'package:reqif_editor/src/core/open_document.dart';
import 'package:reqif_editor/src/document/document_controller.dart';

import 'package:reqif_editor/src/settings/settings_controller.dart';
import 'package:reqif_editor/src/settings/settings_view.dart';

/// Displays a list of last opened files.
class LastOpenedListView extends StatefulWidget {
  static const routeName = '/';

  const LastOpenedListView({
    super.key,
    required this.controller,
    required this.documentController,
  });

  final DocumentController documentController;
  final SettingsController controller;

  @override
  State<LastOpenedListView> createState() => _LastOpenedListViewState();
}

class _LastOpenedListViewState extends State<LastOpenedListView>
    with OpenDocument<LastOpenedListView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.lastUsed),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: ListView.builder(
        restorationId: 'lastOpenedListView',
        itemCount: widget.controller.lastOpenedFiles.length,
        itemBuilder: (BuildContext context, int index) {
          final item = widget.controller.lastOpenedFiles.toList()[index];

          return ListTile(
              title: Text(item.title),
              subtitle: Text("${item.path}\n${item.lastUsed}"),
              leading: const CircleAvatar(
                foregroundImage: AssetImage('assets/images/document.png'),
              ),
              onTap: () {
                openPath(widget.documentController, item.path);
              });
        },
      ),
    );
  }
}
