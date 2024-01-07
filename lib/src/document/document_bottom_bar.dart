// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DocumentBottomBar extends StatefulWidget {
  final DocumentController controller;

  const DocumentBottomBar({Key? key, required this.controller})
      : super(key: key);

  @override
  State<DocumentBottomBar> createState() => _DocumentBottomBarState();
}

class _DocumentBottomBarState extends State<DocumentBottomBar> {
  bool get hasData =>
      widget.controller.length > 0 &&
      widget.controller.visibleDocumentNumber >= 0 &&
      widget.controller.visibleDocumentNumber < widget.controller.length;
  int get partNumber => widget.controller.visibleDocumentPartNumber;
  bool get hasPart =>
      hasData &&
      partNumber >= 0 &&
      partNumber < widget.controller.visibleData.flatDocument.partCount;

  String get searchTerm => hasPart
      ? widget
          .controller.visibleData.searchData[partNumber].searchController.text
      : "";
  bool get hasSearchTerm => hasPart && searchTerm != "";

  int get matches => hasPart
      ? widget.controller.visibleData.searchData[partNumber].matches
      : 0;
  bool get noMatches => hasSearchTerm && matches <= 0;
  bool get caseSensitive => hasPart
      ? widget.controller.visibleData.searchData[partNumber].caseSensitive
      : false;
  set caseSensitive(bool p) {
    if (hasPart) {
      widget.controller.visibleData.searchData[partNumber].caseSensitive = p;
    }
  }

  TextEditingController? get searchController => hasPart
      ? widget.controller.visibleData.searchData[partNumber].searchController
      : null;

  int get currentMatch => hasPart
      ? widget.controller.visibleData.searchData[partNumber].currentMatch
      : -1;
  set currentMatch(int p) {
    if (hasPart) {
      widget.controller.visibleData.searchData[partNumber].currentMatch = p;
    }
  }

  void _updateMatchesAndGotoFirst() {
    if (!hasData) {
      return;
    }
    final data = widget.controller.visibleData;
    data.countMatches(partNumber, searchTerm);
    if (matches > 0) {
      _navigateToMatch(0);
    }
    widget.controller.triggerRebuild();
  }

  void _navigateToMatch(int match) {
    if (!hasData) {
      return;
    }
    final data = widget.controller.visibleData;
    if (matches > 0 && match < matches) {
      final row =
          data.updateSelectionAndFindMatchRow(partNumber, match, searchTerm);
      if (row >= 0) {
        currentMatch = match;
        widget.controller.setPosition(row: row);
      }
      widget.controller.triggerRebuild();
    }
  }

  void _nextMatch({bool backwards = false}) {
    if (!hasData) {
      return;
    }
    if (matches <= 0) {
      return;
    }
    var next = !backwards ? currentMatch + 1 : currentMatch - 1;
    if (next >= matches) {
      next = 0;
    }
    if (next < 0) {
      next = matches - 1;
    }
    _navigateToMatch(next);
  }

  @override
  Widget build(BuildContext context) {
    if (!hasData) {
      return const SizedBox.shrink();
    }
    final locale = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    List<Widget> rowEntries = [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
        child: TextField(
          expands: false,
          minLines: 1,
          maxLines: 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: noMatches
                ? theme.colorScheme.tertiaryContainer
                : theme.colorScheme.surfaceVariant,
            contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            constraints: BoxConstraints.tight(const Size(256, 32)),
            border: OutlineInputBorder(
                borderSide:
                    BorderSide(color: theme.colorScheme.onSurfaceVariant)),
            hintText: AppLocalizations.of(context)!.searchPage,
          ),
          textAlign: TextAlign.left,
          textAlignVertical: TextAlignVertical.top,
          controller: searchController,
          onChanged: (value) {
            setState(() {
              _updateMatchesAndGotoFirst();
            });
          },
        ),
      ),
      IconButton(
          onPressed: () {
            _nextMatch(backwards: true);
          },
          icon: const Icon(Icons.keyboard_arrow_up)),
      IconButton(
          onPressed: () {
            _nextMatch();
          },
          icon: const Icon(Icons.keyboard_arrow_down)),
      Checkbox.adaptive(
          value: caseSensitive,
          onChanged: (value) {
            if (value != null && caseSensitive != value) {
              setState(() {
                caseSensitive = value;
                _updateMatchesAndGotoFirst();
              });
            }
          }),
      Text(locale.caseSensitive),
    ];
    if (searchTerm != "") {
      rowEntries.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: _statusText(context)));
    }
    return Container(
        decoration: BoxDecoration(
            color: theme.colorScheme.onInverseSurface,
            border: const Border(top: BorderSide())),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: rowEntries,
        ));
  }

  Widget _statusText(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    if (matches > 0) {
      return Text(
          "${max(currentMatch + 1, 1)} ${locale.ofSearchBox} $matches ${locale.matches}");
    }
    return Text(locale.noMatches);
  }
}
