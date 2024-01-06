// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DocumentTopBar extends StatelessWidget {
  final QuillController controller;
  final bool navbarIsVisible;
  final bool filterIsVisible;
  final void Function() onNavBarPressed;
  final void Function() onFilterPressed;

  const DocumentTopBar({
    Key? key,
    required this.controller,
    required this.navbarIsVisible,
    required this.filterIsVisible,
    required this.onNavBarPressed,
    required this.onFilterPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onInverseSurface,
            border: Border(
                bottom: BorderSide(
                    color: Theme.of(context).colorScheme.onSurfaceVariant))),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          IconButton(
            onPressed: onNavBarPressed,
            icon: Icon(navbarIsVisible
                ? Icons.navigation_rounded
                : Icons.navigation_outlined),
            tooltip: AppLocalizations.of(context)!.navigationToolTip,
          ),
          IconButton(
            onPressed: onFilterPressed,
            icon: Icon(filterIsVisible
                ? Icons.filter_alt
                : Icons.filter_alt_off_outlined),
            tooltip: AppLocalizations.of(context)!.toggleFilter,
          ),
          VerticalDivider(
              thickness: 3.0,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          QuillToolbar.simple(
            configurations: QuillSimpleToolbarConfigurations(
                controller: controller,
                sharedConfigurations: const QuillSharedConfigurations(),
                buttonOptions: const QuillSimpleToolbarButtonOptions(),
                showAlignmentButtons: false,
                showCodeBlock: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showFontFamily: false,
                showFontSize: false,
                showInlineCode: false,
                showSubscript: false,
                showSuperscript: false,
                showHeaderStyle: false,
                showListCheck: false,
                showListNumbers: false,
                showIndent: false,
                showLink: false,
                showQuote: false,
                showSearchButton: false,
                showUndo: false,
                showRedo: false),
          )
        ]));
  }
}
