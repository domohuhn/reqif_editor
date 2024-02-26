// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/document/navigation_tree_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DocumentNavigation extends StatelessWidget {
  final DocumentController controller;
  final double width;
  const DocumentNavigation(
      {super.key, required this.controller, required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  border: Border(
                      bottom: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer))),
              child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                const Icon(Icons.keyboard_arrow_down_outlined),
                Text(AppLocalizations.of(context)!.openDocuments,
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer()
              ])),
          Expanded(
              child: NavigationTreeView(controller: controller, width: width))
        ]);
  }
}
