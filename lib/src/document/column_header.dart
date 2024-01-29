// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Header for a column of the table. Can show text, or text + a textfield to edit the filter.
///
class ColumnHeader extends StatefulWidget {
  final bool showTextInput;
  final String text;
  final TextEditingController controller;
  final void Function(String)? onChanged;
  const ColumnHeader(
      {super.key,
      this.showTextInput = false,
      required this.text,
      required this.controller,
      this.onChanged});

  @override
  State<ColumnHeader> createState() => _ColumnHeaderState();
}

class _ColumnHeaderState extends State<ColumnHeader> {
  String filterText = "";
  bool filterApplied = true;

  @override
  Widget build(BuildContext context) {
    final title = Text(widget.text);
    var textTheme = Theme.of(context).textTheme.bodySmall;
    if (widget.showTextInput) {
      final inputBox = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        child: TextField(
          style: textTheme,
          controller: widget.controller,
          onChanged: (value) {
            setState(() {
              filterApplied = filterText == value;
            });
          },
          onSubmitted: (value) {
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
            filterText = value;
            filterApplied = true;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(gapPadding: 1.0),
            hintText: AppLocalizations.of(context)!.contains,
            labelText: AppLocalizations.of(context)!.contains,
            filled: !filterApplied,
            fillColor: Theme.of(context).colorScheme.tertiaryContainer,
          ),
        ),
      );
      return Column(
          mainAxisSize: MainAxisSize.min, children: [title, inputBox]);
    }
    return Center(
      child: title,
    );
  }
}
